﻿using billy.Logging;

namespace billy.Api.Client.Queries
{
    public class OwnerQueries : Queries
    {
        public static readonly string ownerDetailsFragment;

        public static readonly string getOwners;
        public static readonly string newOwner;
        public static readonly string updateOwner;
        public static readonly string deleteOwner;
        // public static readonly string setDefaultOwner;
        public static readonly string setOwnerLastCheck;
        public static readonly string getOwnerIdsFromGroups;
        public static readonly string getOwnerIdsForUser;
        public static readonly string getNetworkOwnerships;
        public static readonly string newNetworkOwnership;
        public static readonly string deleteNetworkOwnerships;


        static OwnerQueries()
        {
            try
            {
                ownerDetailsFragment = File.ReadAllText(QueryPath + "owner/fragments/ownerDetails.graphql");

                getOwners = ownerDetailsFragment + File.ReadAllText(QueryPath + "owner/getOwners.graphql");
                newOwner = File.ReadAllText(QueryPath + "owner/newOwner.graphql");
                updateOwner = File.ReadAllText(QueryPath + "owner/updateOwner.graphql");
                deleteOwner = File.ReadAllText(QueryPath + "owner/deleteOwner.graphql");
                //setDefaultOwner = File.ReadAllText(QueryPath + "owner/setDefaultOwner.graphql");
                setOwnerLastCheck = File.ReadAllText(QueryPath + "owner/setOwnerLastCheck.graphql");
                getOwnerIdsFromGroups = ownerDetailsFragment + File.ReadAllText(QueryPath + "owner/getOwnerIdsFromGroups.graphql");
                getOwnerIdsForUser = ownerDetailsFragment + File.ReadAllText(QueryPath + "owner/getOwnerIdsForUser.graphql");
                getNetworkOwnerships = ownerDetailsFragment + File.ReadAllText(QueryPath + "owner/getNetworkOwnerships.graphql");
                newNetworkOwnership = ownerDetailsFragment + File.ReadAllText(QueryPath + "owner/newNetworkOwnership.graphql");
                deleteNetworkOwnerships = ownerDetailsFragment + File.ReadAllText(QueryPath + "owner/deleteNetworkOwnerships.graphql");
            }
            catch (Exception exception)
            {
                Log.WriteError("Initialize OwnerQueries", "Api OwnerQueries could not be loaded.", exception);
                Environment.Exit(-1);
            }
        }
    }
}
