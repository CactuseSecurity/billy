﻿using billy.Report.Filter;
using billy.Report.Filter.Ast;
using billy.Report.Filter.Exceptions;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Text;
using billy.Api.Data;
namespace billy.Test
{
    [TestFixture]
    [Parallelizable]
    public class FilterTest
    {
        [SetUp]
        public void Initialize()
        {

        }

        [Test]
        [Parallelizable]
        public void EmptySearch()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void WhitespaceSearch()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "\t\n  \r  \t \n";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void TextOnlySearch()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "teststring";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            AstNode? ast = Compiler.CompileToAst("teststring");
            DynGraphqlQuery query = Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void AndOr()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "((src=hi) & (dst=test)) | (src = a)";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            var res = Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void TripleOr()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "(src=cactus or dst=cactus or svc=smtps)";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            var res = Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void NotEquals()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "(text!=cactus)";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            var res = Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void ExactEquals()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "(text==cactus)";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            var res = Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void ExactEquals2()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "(gateway = \"checkpoint_demo\" or gateway = \"fortigate_demo\") & dst == IsoAAADray.local";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            var res = Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void ExactEquals3()
        {
            try
            {
                ReportTemplate t = new ReportTemplate();
                t.Filter = "(gateway=\"checkpoint_demo\" or gateway = \"fortigate_demo\") & dst ==";
                t.ReportParams.ReportType = (int) ReportType.Rules;
                var res = Compiler.Compile(t);
                Assert.Fail("Exception should have been thrown");
            }
            catch (SyntaxException exception)
            {
                Assert.AreEqual("No token but one was expected", exception.Message);
            }
        }

        [Test]
        [Parallelizable]
        public void Disabled()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "disabled == true";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            var res = Compiler.Compile(t);
        }

        [Test]
        [Parallelizable]
        public void Brackets()
        {
            ReportTemplate t = new ReportTemplate();
            t.Filter = "src=a&(dst=c)";
            t.ReportParams.ReportType = (int) ReportType.Rules;
            var res = Compiler.Compile(t);
        }

    }
}
