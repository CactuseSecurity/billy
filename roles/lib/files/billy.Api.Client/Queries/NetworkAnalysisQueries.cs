using billy.Logging;

namespace billy.Api.Client.Queries
{
    public class NetworkAnalysisQueries : Queries
    {
        public static readonly string pathAnalysis;

        static NetworkAnalysisQueries() 
        {
            try
            {
                pathAnalysis =
                    File.ReadAllText(QueryPath + "networking/analyzePath.graphql");

            }
            catch (Exception exception)
            {
                Log.WriteError("Initialize Api Queries", "Api Object Queries could not be loaded." , exception);
                Environment.Exit(-1);
            }
        }
    }
}
