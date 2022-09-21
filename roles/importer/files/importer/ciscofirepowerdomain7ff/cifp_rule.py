
from cifp_service import parse_svc_group
from cifp_network import parse_obj_group
import cifp_getter
from fwo_log import getFwoLogger

rule_access_scope_v4 = ['rules_global_header_v4',
                        'rules_adom_v4', 'rules_global_footer_v4']
rule_access_scope_v6 = ['rules_global_header_v6',
                        'rules_adom_v6', 'rules_global_footer_v6']
rule_access_scope = rule_access_scope_v6 + rule_access_scope_v4
rule_nat_scope = ['rules_global_nat', 'rules_adom_nat']
rule_scope = rule_access_scope + rule_nat_scope


def initializeRulebases(raw_config):
    # initialize access rules
    if 'rules_global_header_v4' not in raw_config:
        raw_config.update({'rules_global_header_v4': {}})
    if 'rules_global_header_v6' not in raw_config:
        raw_config.update({'rules_global_header_v6': {}})
    if 'rules_adom_v4' not in raw_config:
        raw_config.update({'rules_adom_v4': {}})
    if 'rules_adom_v6' not in raw_config:
        raw_config.update({'rules_adom_v6': {}})
    if 'rules_global_footer_v4' not in raw_config:
        raw_config.update({'rules_global_footer_v4': {}})
    if 'rules_global_footer_v6' not in raw_config:
        raw_config.update({'rules_global_footer_v6': {}})

    # initialize nat rules
    if 'rules_global_nat' not in raw_config:
        raw_config.update({'rules_global_nat': {}})
    if 'rules_adom_nat' not in raw_config:
        raw_config.update({'rules_adom_nat': {}})


def getAccessPolicy(sessionId, api_url, config, device, limit):
    access_policy = device["accessPolicy"]["id"]
    domain = device["domain"]
    logger = getFwoLogger()

    device["rules"] = cifp_getter.update_config_with_cisco_api_call(sessionId, api_url,
        "fmc_config/v1/domain/" + domain + "/policy/accesspolicies/" + access_policy + "/accessrules", parameters={"expanded": True}, limit=limit)

    return


def getNatPolicy(sid, fm_api_url, raw_config, adom_name, device, limit):
    scope = 'global'
    pkg = device['global_rulebase_name']
    if pkg is not None and pkg != '':   # only read global rulebase if it exists
        for nat_type in ['central/dnat', 'central/dnat6', 'firewall/central-snat-map']:
            cifp_getter.update_config_with_cisco_api_call(
                raw_config['rules_global_nat'], sid, fm_api_url, "/pm/config/" + scope + "/pkg/" + pkg + '/' + nat_type, device['local_rulebase_name'], limit=limit)

    scope = 'adom/'+adom_name
    pkg = device['local_rulebase_name']
    for nat_type in ['central/dnat', 'central/dnat6', 'firewall/central-snat-map']:
        cifp_getter.update_config_with_cisco_api_call(
            raw_config['rules_adom_nat'], sid, fm_api_url, "/pm/config/" + scope + "/pkg/" + pkg + '/' + nat_type, device['local_rulebase_name'], limit=limit)


def normalize_access_rules(full_config, config2import, import_id, mgm_details={}, jwt=None):
    any_nw_svc = {"svc_uid": "any_svc_placeholder", "svc_name": "Any", "svc_comment": "Placeholder service.", 
    "svc_typ": "simple", "ip_proto": -1, "svc_port": 0, "svc_port_end": 65535, "control_id": import_id}
    any_nw_object = {"obj_uid": "any_obj_placeholder", "obj_name": "Any", "obj_comment": "Placeholder object.",
    "obj_typ": "network", "obj_ip": "0.0.0.0/0", "control_id": import_id}
    config2import["service_objects"].append(any_nw_svc)
    config2import["network_objects"].append(any_nw_object)

    rules = []
    for device in full_config["devices"]:
        access_policy = device["accessPolicy"]
        rule_number = 0
        for rule_orig in device["rules"]:
            rule = {'rule_src': 'any', 'rule_dst': 'any', 'rule_svc': 'any',
            'rule_src_refs': 'any_obj_placeholder', 'rule_dst_refs': 'any_obj_placeholder',
            'rule_svc_refs': 'any_svc_placeholder'}
            rule['control_id'] = import_id
            rule['rulebase_name'] = access_policy["name"]
            rule["rule_uid"] = rule_orig["id"]
            rule["rule_name"] = rule_orig["name"]
            rule['rule_type'] = "access"
            rule['rule_num'] = rule_number
            rule['rule_installation'] = None
            rule['parent_rule_id'] = None
            rule['rule_time'] = None
            rule['rule_implied'] = False

            if 'description' in rule_orig:
                rule['rule_comment'] = rule_orig['description']
            else:
                rule["rule_comment"] = None
            if rule_orig["action"] == "ALLOW":
                rule["rule_action"] = "Accept"
            elif rule_orig["action"] == "BLOCK":
                rule["rule_action"] = "Drop"
            elif rule_orig["action"] == "TRUST":
                 rule["rule_action"] = "Accept" #TODO More specific?            
            elif rule_orig["action"] == "MONITOR":
                continue #TODO No access rule (just tracking and logging)
            if rule_orig["enableSyslog"]:
                rule["rule_track"] = "Log"
            else:
                rule["rule_track"] = "None"
            rule["rule_disabled"] = not rule_orig["enabled"]

            if "sourceNetworks" in rule_orig:
                rule['rule_src_refs'], rule["rule_src"] = parse_obj_group(rule_orig["sourceNetworks"], import_id, config2import['network_objects'], rule["rule_uid"])
            if "destinationNetworks" in rule_orig:
                rule['rule_dst_refs'], rule["rule_dst"] = parse_obj_group(rule_orig["destinationNetworks"], import_id, config2import['network_objects'], rule["rule_uid"])
            # TODO source ports
            if "destinationPorts" in rule_orig:
                rule["rule_svc_refs"], rule["rule_svc"] = parse_svc_group(rule_orig["destinationPorts"], import_id, config2import['service_objects'], rule["rule_uid"])

            rule["rule_src_neg"] = False
            rule["rule_dst_neg"] = False
            rule["rule_svc_neg"] = False

            rule_number += 1
            rules.append(rule)

    config2import['rules'] = rules

# TODO NAT
# # pure nat rules
# def normalize_nat_rules(full_config, config2import, import_id, jwt=None):
#     nat_rules = []
#     rule_number = 0

#     for rule_table in rule_nat_scope:
#         for localPkgName in full_config['rules_global_nat']:
#             for rule_orig in full_config[rule_table][localPkgName]:
#                 rule = {'rule_src': '', 'rule_dst': '', 'rule_svc': ''}
#                 if rule_orig['nat'] == 1:   # assuming source nat
#                     rule.update({'control_id': import_id})
#                     # the rulebase_name just has to be a unique string among devices
#                     rule.update({'rulebase_name': localPkgName})
#                     rule.update({'rule_ruleid': rule_orig['policyid']})
#                     rule.update({'rule_uid': rule_orig['uuid']})
#                     # rule.update({ 'rule_num': rule_orig['obj seq']})
#                     rule.update({'rule_num': rule_number})
#                     if 'comments' in rule_orig:
#                         rule.update({'rule_comment': rule_orig['comments']})
#                     # not used for nat rules
#                     rule.update({'rule_action': 'Drop'})
#                     # not used for nat rules
#                     rule.update({'rule_track': 'None'})

#                     rule['rule_src'] = extend_string_list(
#                         rule['rule_src'], rule_orig, 'orig-addr', list_delimiter, jwt=jwt, import_id=import_id)
#                     rule['rule_dst'] = extend_string_list(
#                         rule['rule_dst'], rule_orig, 'dst-addr', list_delimiter, jwt=jwt, import_id=import_id)

#                     if rule_orig['protocol'] == 17:
#                         svc_name = 'udp_' + str(rule_orig['orig-port'])
#                     elif rule_orig['protocol'] == 6:
#                         svc_name = 'tcp_' + str(rule_orig['orig-port'])
#                     else:
#                         svc_name = 'svc_' + str(rule_orig['orig-port'])
#                     # need to create a helper service object and add it to the nat rule, also needs to be added to service list

#                     if not 'service_objects' in config2import:  # is normally defined
#                         config2import['service_objects'] = []
#                     config2import['service_objects'].append(create_svc_object(
#                         import_id=import_id, name=svc_name, proto=rule_orig['protocol'], port=rule_orig['orig-port'], comment='service created by FWO importer for NAT purposes'))
#                     rule['rule_svc'] = svc_name

#                     #rule['rule_src'] = common.extend_string_list(rule['rule_src'], rule_orig, 'srcaddr6', list_delimiter, jwt=jwt, import_id=import_id)
#                     #rule['rule_dst'] = common.extend_string_list(rule['rule_dst'], rule_orig, 'dstaddr6', list_delimiter, jwt=jwt, import_id=import_id)

#                     if len(rule_orig['srcintf']) > 0:
#                         # todo: currently only using the first zone
#                         rule.update(
#                             {'rule_from_zone': rule_orig['srcintf'][0]})
#                     if len(rule_orig['dstintf']) > 0:
#                         # todo: currently only using the first zone
#                         rule.update({'rule_to_zone': rule_orig['dstintf'][0]})

#                     rule.update({'rule_src_neg': False})
#                     rule.update({'rule_dst_neg': False})
#                     rule.update({'rule_svc_neg': False})
#                     rule.update({'rule_src_refs': resolve_raw_objects(rule['rule_src'], list_delimiter, full_config, 'name', 'uuid', rule_type=rule_table)},
#                                 jwt=jwt, import_id=import_id, rule_uid=rule_orig['uuid'], object_type='network object')
#                     rule.update({'rule_dst_refs': resolve_raw_objects(rule['rule_dst'], list_delimiter, full_config, 'name', 'uuid', rule_type=rule_table)},
#                                 jwt=jwt, import_id=import_id, rule_uid=rule_orig['uuid'], object_type='network object')
#                     # services do not have uids, so using name instead
#                     rule.update({'rule_svc_refs': rule['rule_svc']})
#                     rule.update({'rule_type': 'original'})
#                     rule.update({'rule_installon': None})
#                     if 'status' in rule_orig and (rule_orig['status'] == 'enable' or rule_orig['status'] == 1):
#                         rule.update({'rule_disabled': False})
#                     else:
#                         rule.update({'rule_disabled': True})
#                     rule.update({'rule_implied': False})
#                     rule.update({'rule_time': None})
#                     rule.update({'parent_rule_id': None})

#                     nat_rules.append(rule)

#                     ############## now adding the xlate rule part ##########################
#                     xlate_rule = dict(rule)  # copy the original (match) rule
#                     xlate_rule.update(
#                         {'rule_src': '', 'rule_dst': '', 'rule_svc': ''})
#                     xlate_rule['rule_src'] = extend_string_list(
#                         xlate_rule['rule_src'], rule_orig, 'orig-addr', list_delimiter, jwt=jwt, import_id=import_id)
#                     xlate_rule['rule_dst'] = 'Original'

#                     if rule_orig['protocol'] == 17:
#                         svc_name = 'udp_' + str(rule_orig['nat-port'])
#                     elif rule_orig['protocol'] == 6:
#                         svc_name = 'tcp_' + str(rule_orig['nat-port'])
#                     else:
#                         svc_name = 'svc_' + str(rule_orig['nat-port'])
#                     # need to create a helper service object and add it to the nat rule, also needs to be added to service list!
#                     # cifp_service.create_svc_object(name=svc_name, proto=rule_orig['protocol'], port=rule_orig['orig-port'], comment='service created by FWO importer for NAT purposes')
#                     config2import['service_objects'].append(create_svc_object(
#                         import_id=import_id, name=svc_name, proto=rule_orig['protocol'], port=rule_orig['nat-port'], comment='service created by FWO importer for NAT purposes'))
#                     xlate_rule['rule_svc'] = svc_name

#                     xlate_rule.update({'rule_src_refs': resolve_objects(
#                         xlate_rule['rule_src'], list_delimiter, full_config, 'name', 'uuid', rule_type=rule_table, jwt=jwt, import_id=import_id)})
#                     xlate_rule.update({'rule_dst_refs': resolve_objects(
#                         xlate_rule['rule_dst'], list_delimiter, full_config, 'name', 'uuid', rule_type=rule_table, jwt=jwt, import_id=import_id)})
#                     # services do not have uids, so using name instead
#                     xlate_rule.update(
#                         {'rule_svc_refs': xlate_rule['rule_svc']})

#                     xlate_rule.update({'rule_type': 'xlate'})

#                     nat_rules.append(xlate_rule)
#                     rule_number += 1
#     config2import['rules'].extend(nat_rules)


# def check_headers_needed(full_config, rule_types):
#     found_v4 = False
#     found_v6 = False
#     for rule_table in rule_types:
#         if full_config[rule_table] is not None:
#             if rule_table in rule_access_scope_v4:
#                 found_v4 = True
#             if rule_table in rule_access_scope_v6:
#                 found_v6 = True
#     if found_v4 and found_v6:
#         return True, True
#     return False, False


# def insert_header(rules, import_id, header_text, rulebase_name, rule_uid, rule_number, src_refs, dst_refs):
#     rule = {
#         "control_id": import_id,
#         "rule_head_text": header_text,
#         "rulebase_name": rulebase_name,
#         "rule_ruleid": None,
#         "rule_uid":  rule_uid + rulebase_name,
#         "rule_num": rule_number,
#         "rule_disabled": False,
#         "rule_src": "all",
#         "rule_dst": "all",
#         "rule_svc": "ALL",
#         "rule_src_neg": False,
#         "rule_dst_neg": False,
#         "rule_svc_neg": False,
#         "rule_src_refs": src_refs,
#         "rule_dst_refs": dst_refs,
#         "rule_svc_refs": "ALL",
#         "rule_action": "Accept",
#         "rule_track": "None",
#         "rule_installon": None,
#         "rule_time": None,
#         "rule_type": "access",
#         "parent_rule_id": None,
#         "rule_implied": False,
#         "rule_comment": None
#     }
#     rules.append(rule)


# def create_xlate_rule(rule):
#     xlate_rule = copy.deepcopy(rule)
#     rule['rule_type'] = 'combined'
#     xlate_rule['rule_type'] = 'xlate'
#     xlate_rule['rule_comment'] = None
#     xlate_rule['rule_disabled'] = False
#     xlate_rule['rule_src'] = 'Original'
#     xlate_rule['rule_src_refs'] = 'Original'
#     xlate_rule['rule_dst'] = 'Original'
#     xlate_rule['rule_dst_refs'] = 'Original'
#     xlate_rule['rule_svc'] = 'Original'
#     xlate_rule['rule_svc_refs'] = 'Original'
#     return xlate_rule


# def handle_combined_nat_rule(rule, rule_orig, config2import, nat_rule_number, import_id, localPkgName, device_name):
#     # now dealing with VIPs (dst NAT part) of combined rules
#     logger = getFwoLogger()
#     xlate_rule = None

#     # dealing with src NAT part of combined rules
#     if "nat" in rule_orig and rule_orig["nat"] == 1:
#         logger.debug("found mixed Access/NAT rule no. " + str(nat_rule_number))
#         nat_rule_number += 1
#         xlate_rule = create_xlate_rule(rule)
#         if 'ippool' in rule_orig:
#             if rule_orig['ippool'] == 0:  # hiding behind outbound interface
#                 interface_name = 'unknownIF'
#                 destination_interface_ip = '0.0.0.0'
#                 destination_ip = get_first_ip_of_destination(
#                     rule['rule_dst_refs'], config2import)  # get an ip of destination
#                 if destination_ip is None:
#                     logger.warning(
#                         'src nat behind interface: found no valid destination ip in rule with UID ' + rule['rule_uid'])
#                 else:
#                     matching_route = get_matching_route(
#                         destination_ip, config2import['networking'][device_name]['routingv4'])
#                     if matching_route is None:
#                         logger.warning('src nat behind interface: found no matching route in rule with UID '
#                                        + rule['rule_uid'] + ', dest_ip: ' + destination_ip)
#                     else:
#                         destination_interface_ip = get_ip_of_interface(
#                             matching_route['interface'], config2import['networking'][device_name]['interfaces'])
#                         # ['name']
#                         interface_name = matching_route['interface']
#                         hideInterface = interface_name
#                         if destination_interface_ip is None:
#                             logger.warning('src nat behind interface: found no matching interface IP in rule with UID '
#                                            + rule['rule_uid'] + ', dest_ip: ' + destination_ip)

#                 # add dummy object "outbound-interface"
#                 obj_name = 'hide_IF_ip_' + hideInterface + '_' + destination_interface_ip
#                 obj_comment = 'FWO auto-generated dummy object for source nat'
#                 obj = create_network_object(
#                     import_id, obj_name, 'host', destination_interface_ip + '/32', obj_name, 'black', obj_comment, 'global')

#                 if obj not in config2import['network_objects']:
#                     config2import['network_objects'].append(obj)
#                 xlate_rule['rule_src'] = obj_name
#                 xlate_rule['rule_src_refs'] = obj_name

#             elif rule_orig['ippool'] == 1:  # hiding behind one ip of an ip pool
#                 poolNameArray = rule_orig['poolname']
#                 if len(poolNameArray) > 0:
#                     if len(poolNameArray) > 1:
#                         logger.warning(
#                             "found more than one ippool - ignoring all but first pool")
#                     poolName = poolNameArray[0]
#                     xlate_rule['rule_src'] = poolName
#                     xlate_rule['rule_src_refs'] = poolName
#                 else:
#                     logger.warning(
#                         "found ippool rule without ippool: " + rule['rule_uid'])
#             else:
#                 logger.warning(
#                     "found ippool rule with unexpected ippool value: " + rule_orig['ippool'])

#         if 'natip' in rule_orig and rule_orig['natip'] != ["0.0.0.0", "0.0.0.0"]:
#             logger.warning(
#                 "found explicit natip rule - ignoring for now: " + rule['rule_uid'])
#             # need example for interpretation of config

#     # todo: find out how match-vip=1 influences natting (only set in a few vip-nat rules)
#     # if "match-vip" in rule_orig and rule_orig["match-vip"]==1:
#     #     logger.warning("found VIP destination Access/NAT rule (but not parsing yet); no. " + str(vip_nat_rule_number))
#     #     vip_nat_rule_number += 1

#     # deal with vip natting: check for each (dst) nw obj if it contains "obj_nat_ip"
#     rule_dst_list = rule['rule_dst'].split(list_delimiter)
#     nat_object_list = extract_nat_objects(
#         rule_dst_list, config2import['network_objects'])

#     if len(nat_object_list) > 0:
#         if xlate_rule is None:  # no source nat, so we create the necessary nat rule here
#             xlate_rule = create_xlate_rule(rule)
#         xlate_dst = []
#         xlate_dst_refs = []
#         for nat_obj in nat_object_list:
#             if 'obj_ip_end' in nat_obj:  # this nat obj is a range - include the end ip in name and uid as well to avoid akey conflicts
#                 xlate_dst.append(
#                     nat_obj['obj_nat_ip'] + '-' + nat_obj['obj_ip_end'] + nat_postfix)
#                 nat_ref = nat_obj['obj_nat_ip']
#                 if 'obj_nat_ip_end' in nat_obj:
#                     nat_ref += '-' + nat_obj['obj_nat_ip_end'] + nat_postfix
#                 xlate_dst_refs.append(nat_ref)
#             else:
#                 xlate_dst.append(nat_obj['obj_nat_ip'] + nat_postfix)
#                 xlate_dst_refs.append(nat_obj['obj_nat_ip'] + nat_postfix)
#         xlate_rule['rule_dst'] = list_delimiter.join(xlate_dst)
#         xlate_rule['rule_dst_refs'] = list_delimiter.join(xlate_dst_refs)
#     # else: (no nat object found) no dnatting involved, dst stays "Original"

#     return xlate_rule


# def insert_headers(rule_table, first_v6, first_v4, full_config, rules, import_id, localPkgName, src_ref_all, dst_ref_all, rule_number):
#     if rule_table in rule_access_scope_v6 and first_v6:
#         insert_header(rules, import_id, "IPv6 rules", localPkgName,
#                       "IPv6HeaderText", rule_number, src_ref_all, dst_ref_all)
#         rule_number += 1
#         first_v6 = False
#     elif rule_table in rule_access_scope_v4 and first_v4:
#         insert_header(rules, import_id, "IPv4 rules", localPkgName,
#                       "IPv4HeaderText", rule_number, src_ref_all, dst_ref_all)
#         rule_number += 1
#         first_v4 = False
#     if rule_table == 'rules_adom_v4' and len(full_config['rules_adom_v4'][localPkgName]) > 0:
#         insert_header(rules, import_id, "Adom Rules IPv4", localPkgName,
#                       "IPv4AdomRules", rule_number, src_ref_all, dst_ref_all)
#         rule_number += 1
#     elif rule_table == 'rules_adom_v6' and len(full_config['rules_adom_v6'][localPkgName]) > 0:
#         insert_header(rules, import_id, "Adom Rules IPv6", localPkgName,
#                       "IPv6AdomRules", rule_number, src_ref_all, dst_ref_all)
#         rule_number += 1
#     elif rule_table == 'rules_global_header_v4' and len(full_config['rules_global_header_v4'][localPkgName]) > 0:
#         insert_header(rules, import_id, "Global Header Rules IPv4", localPkgName,
#                       "IPv4GlobalHeaderRules", rule_number, src_ref_all, dst_ref_all)
#         rule_number += 1
#     elif rule_table == 'rules_global_header_v6' and len(full_config['rules_global_header_v6'][localPkgName]) > 0:
#         insert_header(rules, import_id, "Global Header Rules IPv6", localPkgName,
#                       "IPv6GlobalHeaderRules", rule_number, src_ref_all, dst_ref_all)
#         rule_number += 1
#     elif rule_table == 'rules_global_footer_v4' and len(full_config['rules_global_footer_v4'][localPkgName]) > 0:
#         insert_header(rules, import_id, "Global Footer Rules IPv4", localPkgName,
#                       "IPv4GlobalFooterRules", rule_number, src_ref_all, dst_ref_all)
#         rule_number += 1
#     elif rule_table == 'rules_global_footer_v6' and len(full_config['rules_global_footer_v6'][localPkgName]) > 0:
#         insert_header(rules, import_id, "Global Footer Rules IPv6", localPkgName,
#                       "IPv6GlobalFooterRules", rule_number, src_ref_all, dst_ref_all)
#         rule_number += 1
#     return rule_number, first_v4, first_v6


# def extract_nat_objects(nwobj_list, all_nwobjects):
#     nat_obj_list = []
#     for obj in nwobj_list:
#         for obj2 in all_nwobjects:
#             if obj2['obj_name'] == obj:
#                 if 'obj_nat_ip' in obj2:
#                     nat_obj_list.append(obj2)
#                 break
#         # if obj in all_nwobjects and 'obj_nat_ip' in all_nwobjects[obj]:
#         #     nat_obj_list.append(obj)
#     return nat_obj_list
