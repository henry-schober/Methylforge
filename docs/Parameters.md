# Parameter Documentation

These parameters can be changed and or added to your config file

> Pipeline Parameters must be provided through CLI or in the `yaml` or `json` file provided with Nextflows `-params-file` option

```
    pore_type = "r10.4.1"            
    // e.g., "r10.4.1"
    
    chemistry_type = "e8.2"      
    // e.g., "e8.2" for Kit 14
    
    translocation_speed = "400bps"  
    // options: "130bps", "260bps", "400bps"
    
    model_version = "v5.0.0"        
    // e.g., "v4.3.0"
    
    modification_name = "5mCG_5hmCG"    
    //options:  "6mA" or "5mCG_5hmCG"
    
    modification_version = "v3"     
    // options:  v1, v2, v3

    model_type = "sup"
    // options : sup, hac, fast

```

> These parameter options match available models for Dorad. Find the model you want to use <u>[**here**](https://github.com/nanoporetech/dorado?tab=readme-ov-file#available-basecalling-models)</u> and cross reference with this list of [Dorado Model names](ModelList.txt)



