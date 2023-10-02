﻿using System.Diagnostics;
using billy.Api.Data;
using billy.Api.Client;
using billy.Logging;

namespace billy.Recert
{
    public class RecertRefresh
    {
        private readonly ApiConnection apiConnection;

        public RecertRefresh (ApiConnection apiConnectionIn)
        {
            apiConnection = apiConnectionIn;
        }

        public async Task<bool> RecalcRecerts()
        {
            double refreshDuration = 0;
            Stopwatch watch = new System.Diagnostics.Stopwatch();
            string secs = "";
            var noVariables = new { };

            try
            {
                watch.Start();
                List<FwoOwner> owners = await apiConnection.SendQueryAsync<List<FwoOwner>>(billy.Api.Client.Queries.OwnerQueries.getOwners);
                List<Management> managements = await apiConnection.SendQueryAsync<List<Management>>(billy.Api.Client.Queries.DeviceQueries.getManagementDetailsWithoutSecrets);
                ReturnId[]? returnIds =
                    (await apiConnection.SendQueryAsync<NewReturning>(billy.Api.Client.Queries.RecertQueries.clearOpenRecerts, noVariables)).ReturnIds;
                // the clearOpenRecerts refreshes materialized view view_rule_with_owner as a side-effect
                watch.Stop();
                refreshDuration = watch.ElapsedMilliseconds / 1000.0;
                secs = refreshDuration.ToString("0.00");
                Log.WriteDebug("Refresh materialized view view_rule_with_owner", $"refresh took {secs} seconds");

                foreach (FwoOwner owner in owners)
                    await RecalcRecertsOfOwner(owner, managements);
            }
            catch (Exception)
            {
                return true;
            }
            return false;
        }

        private async Task RecalcRecertsOfOwner(FwoOwner owner, List<Management> managements)
        {
            double refreshDuration = 0;
            Stopwatch watch = new System.Diagnostics.Stopwatch();
            string secs = "";
            watch.Start();

            foreach (Management mgm in managements)
            {
                List<RecertificationBase> currentRecerts =
                    await apiConnection.SendQueryAsync<List<RecertificationBase>>(billy.Api.Client.Queries.RecertQueries.getOpenRecerts, new { ownerId = owner.Id, mgmId = mgm.Id });

                if (currentRecerts.Count > 0)
                {
                    ReturnId[]? returnedIds = (await apiConnection.SendQueryAsync<NewReturning>(billy.Api.Client.Queries.RecertQueries.addRecertEntries, new { recerts = currentRecerts })).ReturnIds;
                }
            }

            watch.Stop();
            refreshDuration = watch.ElapsedMilliseconds / 1000.0;
            secs = refreshDuration.ToString("0.00");
            Log.WriteDebug("Refresh Recertification", $"refresh for owner {owner.Name} took {secs} seconds");
        }

    }
}

