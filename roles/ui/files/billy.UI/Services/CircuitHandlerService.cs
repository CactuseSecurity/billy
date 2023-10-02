using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Components.Server.Circuits;
using billy.Logging;
using billy.Api.Data;

namespace billy.Ui.Services
{
    public class CircuitHandlerService : CircuitHandler
    {
        public UiUser? User { get; set; }

        public override Task OnCircuitClosedAsync(Circuit circuit, CancellationToken cancellationToken)
        {
            if (User != null)
            {
                Log.WriteAudit($"Session of \"{User.Name}\" closed", $"Session of user \"{User.Name}\" (last logged in) with DN: \"{User.Dn}\" was closed.");
            }
            return Task.CompletedTask;
        }
    }
}
