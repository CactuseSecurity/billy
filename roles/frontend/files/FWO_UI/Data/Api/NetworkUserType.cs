﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace FWO.Ui.Data.Api
{
    public class NetworkUserType
    {
        [JsonPropertyName("usr_typ_name")]
        public string Name { get; set; }
    }
}
