﻿using billy.Api.Data;

namespace billy.Ui.Services
{
    public static class DefaultInit
    {
        public static void DoNothing(Exception? e, string t, string m, bool E) {}
        public static async Task DoNothing() {}
        public static async Task DoNothing(string s) {}
        public static async Task DoNothing(RequestStatefulObject s) {}
        public static async Task DoNothing(RequestReqTask r) {}
        public static async Task DoNothing(RequestImplTask i) {}
    }
}
