using billy.Report.Filter.Ast;
using billy.Api.Data;
using billy.Logging;

namespace billy.Report.Filter
{
    public class Compiler
    {
        public static AstNode? CompileToAst(string input)
        {
            Scanner scanner = new Scanner(input);
            List<Token> tokens = scanner.Scan();
            if(tokens.Count > 0)
            {
                Parser parser = new Parser(tokens);
                return parser.Parse();
            }
            else return null;
        }

        public static DynGraphqlQuery Compile(ReportTemplate filter)
        {
            Log.WriteDebug("Filter", $"Input: \"{filter.Filter}\", Report Type: \"${filter.ReportParams.ReportType}\", Device Filter: \"{filter.ReportParams.DeviceFilter}\"");
            return DynGraphqlQuery.GenerateQuery(filter, CompileToAst(filter.Filter));
        }
    }
}
