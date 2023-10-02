using System;
using System.Collections.Generic;
using System.Text;

namespace billy.Report.Filter.Exceptions
{
    public class SyntaxException : FilterException
    {
        public SyntaxException(string message, Range errorPosition) : base(message, errorPosition)
        {

        }
    }
}
