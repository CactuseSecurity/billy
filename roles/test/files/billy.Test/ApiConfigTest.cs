using billy.Api.Client;
using billy.Config.Api;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace billy.Test
{
    [TestFixture]
    internal class ApiConfigTest
    {
        public ApiConfigTest()
        {

        }

        /// <summary>
        /// Run before EACH test.
        /// </summary>
        [SetUp]
        public void Setup()
        {

        }

        [Test]
        public async Task ReadGlobalConfig()
        {
            //ApiConnection apiConnection = new GraphQlApiConnection("");
            //GlobalConfig globalConfig = await GlobalConfig.ConstructAsync();
        }

        [Test]
        public void ReadUserConfig()
        {
            //UserConfig userConfig = new UserConfig()
        }

        [Test]
        public void WriteGlobalConfig()
        {

        }

        [Test]
        public void WriteUserConfig()
        {

        }
    }
}
