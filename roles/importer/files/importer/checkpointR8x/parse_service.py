import argparse
import json
import re
import logging

csv_delimiter = '%'
list_delimiter = '|'
line_delimiter = "\n"
found_rulebase = False
section_header_uids=[]

# the following is the static across all installations unique any obj uid 
# cannot fetch the Any object via API (<=1.7) at the moment
# therefore we have a workaround adding the object manually (as svc and nw)
any_obj_uid = "97aeb369-9aea-11d5-bd16-0090272ccb30"
# todo: read this from config (vom API 1.6 on it is fetched)


def csv_dump_svc_obj(svc_obj):
    #print("dumping svc: " + svc_obj['svc_name'] + ", svc_member_refs: " + svc_obj['svc_member_refs'])
    result_line = '"' + args.import_id + '"' + csv_delimiter  # control_id
    result_line += '"' + svc_obj['svc_name'] + '"' + csv_delimiter  # svc_name
    result_line += '"' + svc_obj['svc_typ'] + '"' + csv_delimiter  # svc_typ
    result_line += '"' + svc_obj['svc_typ'] + '"' + csv_delimiter  # svc_prod_specific
    result_line += '"' + svc_obj['svc_member_names'] + '"' + csv_delimiter  # svc_member_names
    result_line += '"' + svc_obj['svc_member_refs'] + '"' + csv_delimiter  # obj_member_refs
    result_line += '"' + svc_obj['svc_color'] + '"' + csv_delimiter  # svc_color
    result_line += '"' + svc_obj['ip_proto'] + '"' + csv_delimiter  # ip_proto
    result_line += str(svc_obj['svc_port']) + csv_delimiter  # svc_port
    result_line += str(svc_obj['svc_port_end']) + csv_delimiter  # svc_port_end
    result_line += csv_delimiter  # result_line += '"' + svc_obj['svc_source_port'] + '"' + csv_delimiter       # svc_source_port
    result_line += csv_delimiter  # result_line += '"' + svc_obj['svc_source_port_end'] + '"' + csv_delimiter   # svc_source_port_end
    result_line += '"' + svc_obj['svc_comment'] + '"' + csv_delimiter  # svc_comment
    result_line += '"' + str(svc_obj['rpc_nr']) + '"' + csv_delimiter  # rpc_nr
    result_line += csv_delimiter  # result_line += '"' + svc_obj['svc_timeout_std'] + '"' + csv_delimiter       # svc_timeout_std
    result_line += str(svc_obj['svc_timeout']) + csv_delimiter  # svc_timeout
    result_line += '"' + svc_obj['svc_uid'] + '"' + csv_delimiter  # svc_uid
    result_line += csv_delimiter  # last_change_admin
    #  last_change_time
    result_line += line_delimiter
    return result_line


# collect_svcobjects writes svc info into global users dict
def collect_svc_objects(object_table):
    global svc_objects
    result = ''
    svc_obj_tables = [
        'services-tcp', 'services-udp', 'service-groups', 'services-dce-rpc', 'services-rpc',
        'services-other', 'services-icmp', 'services-icmp6' 
    ]

    if object_table['object_type'] in svc_obj_tables:
        proto = ''
        session_timeout = ''
        typ = 'undef'
        proto = '0'
        if object_table['object_type'] == 'service-groups':
            typ = 'group'
            proto = '0'
        if object_table['object_type'] == 'services-tcp':
            typ = 'simple'
            proto = '6'
        if object_table['object_type'] == 'services-udp':
            typ = 'simple'
            proto = '17'
        if object_table['object_type'] == 'services-dce-rpc' or object_table['object_type'] == 'services-rpc':
            typ = 'simple'
            proto = ''
        if object_table['object_type'] == 'services-other':
            typ = 'simple'
            proto = '0'
        if object_table['object_type'] == 'services-icmp' or object_table['object_type'] == 'services-icmp6':
            typ = 'simple'
            proto = '1'
        for chunk in object_table['object_chunks']:
            for obj in chunk['objects']:
                ip_addr = ''
                member_refs = ''
                member_names = ''
                port = ''
                port_end = ''
                rpc_nr = ''
                if 'members' in obj:
                    member_refs = ''
                    for member in obj['members']:
                        member_refs += member + list_delimiter
                    member_refs = member_refs[:-1]
                if 'session-timeout' in obj:
                    session_timeout = str(obj['session-timeout'])
                if 'interface-uuid' in obj:
                    rpc_nr = obj['interface-uuid']
                if 'program-number' in obj:
                    rpc_nr = obj['program-number']
                if 'port' in obj:
                    port = str(obj['port'])
                    port_end = port
                    pattern = re.compile('^\>(\d+)$')
                    match = pattern.match(port)
                    if match:
                        port = str(int(match.group()[1:]) + 1)
                        port_end = str(65535)
                    pattern = re.compile('^\<(\d+)$')
                    match = pattern.match(port)
                    if match:
                        port = str(1)
                        port_end = str(int(match.group()[1:]) - 1)
                    pattern = re.compile('^(\d+)\-(\d+)$')
                    match = pattern.match(port)
                    if match:
                        port, port_end = match.group().split('-')
                else:
                    # rpc, group - setting ports to 0
                    port = '0'
                    port_end = '0'
                if not 'color' in obj:
                    # print('warning: no color found for service ' + obj['name'])
                    obj['color'] = 'black'
                svc_objects.extend([{'svc_uid': obj['uid'], 'svc_name': obj['name'], 'svc_color': obj['color'],
                                     'svc_comment': obj['comments'],
                                     'svc_typ': typ, 'svc_port': port, 'svc_port_end': port_end,
                                     'svc_member_refs': member_refs,
                                     'svc_member_names': '',
                                     'ip_proto': proto,
                                     'svc_timeout': session_timeout,
                                     'rpc_nr': rpc_nr}])


# return name of nw_objects element where obj_uid = uid
def resolve_svc_uid_to_name(uid):
    global svc_objects
    for obj in svc_objects:
        if obj['svc_uid'] == uid:
            return obj['svc_name']
    return 'ERROR: uid ' + uid + ' not found'


def add_member_names_for_svc_group(idx):
    global svc_objects
    member_names = ''
    group = svc_objects.pop(idx)
    svc_member_refs = group['svc_member_refs'].split(list_delimiter)

    for ref in svc_member_refs:
        member_name = resolve_svc_uid_to_name(ref)
        #print ("found member of group " + group['svc_name'] + ": " + member_name)
        member_names += member_name + list_delimiter
    group['svc_member_names'] = member_names[:-1]
    svc_objects.insert(idx, group)