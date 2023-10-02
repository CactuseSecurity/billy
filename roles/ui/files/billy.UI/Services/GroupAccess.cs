﻿using System.Net;
using billy.Api.Data;
using billy.Config.Api;
using billy.Middleware.Client;
using billy.Middleware.RequestParameters;
using RestSharp;

namespace billy.Ui.Services
{
    public class GroupAccess
    {
        static public async Task<List<UserGroup>> GetGroupsFromInternalLdap(MiddlewareClient middlewareClient, UserConfig userConfig,
            Action<Exception?, string, string, bool> DisplayMessageInUi, bool ownerGroupsOnly = false)
        {
            List<UserGroup> groups = new List<UserGroup>();
            RestResponse<List<GroupGetReturnParameters>> middlewareServerGroupsResponse = await middlewareClient.GetInternalGroups();
            if (middlewareServerGroupsResponse.StatusCode != HttpStatusCode.OK || middlewareServerGroupsResponse.Data == null)
            {
                DisplayMessageInUi(null, userConfig.GetText("fetch_groups"), userConfig.GetText("E5231"), true);
            }
            else
            {
                foreach (var ldapUserGroup in middlewareServerGroupsResponse.Data)
                {
                    if(!ownerGroupsOnly || ldapUserGroup.OwnerGroup)
                    {
                        UserGroup group = new UserGroup()
                        { 
                            Dn = ldapUserGroup.GroupDn,
                            Name = (new DistName(ldapUserGroup.GroupDn)).Group,
                            OwnerGroup = ldapUserGroup.OwnerGroup
                        };
                        foreach (var userDn in ldapUserGroup.Members)
                        {
                            UiUser newUser = new UiUser() { Dn = userDn, Name = (new DistName(userDn)).UserName };
                            group.Users.Add(newUser);
                        }
                        groups.Add(group);
                    }
                }
            }
            return groups;
        }

        static public async Task<List<string>> GetGroupDnsFromInternalLdap(MiddlewareClient middlewareClient, UserConfig userConfig, Action<Exception?, string, string, bool> DisplayMessageInUi)
        {
            List<string> groupDns = new List<string>();
            RestResponse<List<GroupGetReturnParameters>> middlewareServerGroupsResponse = await middlewareClient.GetInternalGroups();
            if (middlewareServerGroupsResponse.StatusCode != HttpStatusCode.OK || middlewareServerGroupsResponse.Data == null)
            {
                DisplayMessageInUi(null, userConfig.GetText("fetch_groups"), userConfig.GetText("E5231"), true);
            }
            else
            {
                foreach (var ldapUserGroup in middlewareServerGroupsResponse.Data)
                {
                    groupDns.Add(ldapUserGroup.GroupDn);
                }
            }
            return groupDns;
        }
    }
}
