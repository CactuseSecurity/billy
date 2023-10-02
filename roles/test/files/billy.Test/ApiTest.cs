using System;
using System.Threading.Tasks;
using billy.Api.Client;
using NUnit.Framework;
using billy.Api.Data;
using billy.Config.File;
using billy.Middleware.Client;
using Microsoft.IdentityModel.Tokens;
using billy.Middleware.RequestParameters;
using billy.Logging;

namespace billy.Test
{
    [TestFixture]
    [Parallelizable]
    public class ApiTest
    {
        ApiConnection apiConnection;

        public ApiTest()
        {
            // ConfigFile configConnection = new ConfigFile();
            // Dictionary<string, string> apiTestUserCredentials = configConnection.ReadAdditionalConfigFile("secrets/TestUserCreds.json", new List<string> { "user", "password" });
            // string ApiUri = configConnection.ApiServerUri;
            // string MiddlewareUri = configConnection.MiddlewareServerUri;
            // string ProductVersion = configConnection.ProductVersion;
            // RsaSecurityKey jwtPublicKey = configConnection.JwtPublicKey;
            // string middlewareServerUri = configConnection.MiddlewareServerUri;
            // string apiServerUri = configConnection.ApiServerUri;
            // MiddlewareClient middlewareClient = new MiddlewareClient(MiddlewareUri);
            // AuthenticationTokenGetParameters authenticationParameters = new AuthenticationTokenGetParameters
            // {
            //     Password = apiTestUserCredentials["password"],
            //     Username = apiTestUserCredentials["user"]
            // };
            // string jwt = middlewareClient.AuthenticateUser(authenticationParameters).Result.Data;
            // apiConnection = new APIConnection(apiServerUri);
            // apiConnection.SetAuthHeader(jwt);
            return;
        }

        /// <summary>
        /// Run before EACH test.
        /// </summary>
        [SetUp]
        public void Setup()
        {

        }

        [Test]
        public async Task QueryTestIpProto()
        {
            // string query = @"
            //         query ipProtoTest 
            //         {
            //             stm_ip_proto (where: {ip_proto_id: {_eq: 6 } }) 
            //                 {
            //                     id: ip_proto_id
            //                     name: ip_proto_name
            //                 }
            //         }";

            // NetworkProtocol networkProtocol = new NetworkProtocol();
            // networkProtocol = (await apiConnection.SendQueryAsync<NetworkProtocol[]>(query, new { }))[0];
            // Assert.AreEqual(networkProtocol.Name, "TCP", "wrong result of protocol API query");
        }
    }
}
