package;
using StringTools;
import haxe.Json;
import sys.FileSystem;

// Class to help with loading content and getting data from them


typedef ContentV3Metadata = {
    var name: String;
    var description: String;
    var version: String;
    var credits: Array<Array<String>>;
	var requires_restart: Bool;
	var dependencies: Array<String>;
    var engine_version: String;
	var content_format: Int;
}

class ContentHelper {
	public static var loadedContentDirectories:Array<String> = [];
    public static var loadedContent:Array<String> = [];
	public static var contentMetadata:Map<String, ContentV3Metadata> = [];
	public static var namespaceMap:Map<String, Array<String>> = ["troll_engine" => []]; // namespace => [contentWithNamespace], used to speed up lookups

    static function getJson(path:String): Dynamic
    {
		var jsonPath = Paths.mods(path);
		var rawJson:Null<String> = Paths.getContent(jsonPath);    
		if (rawJson != null && rawJson.length > 0)
			return Json.parse(rawJson);

        return null;
    }

    public static function loadContent(){
        loadedContent = [];

		for (modDir in Paths.getModDirectories(false))
		{
            var is_new:Bool = false;
            // TODO: check if its enabled

			var metadataJson:Dynamic = getJson(modDir + "/metadata.json");
			if (metadataJson != null && Reflect.field(metadataJson, "content_format") != null)
			{
				var format:Dynamic = Reflect.field(metadataJson, "content_format");
                if(format == 3){
                    is_new = true;
					var metadata:ContentV3Metadata = cast metadataJson;
                    contentMetadata.set(modDir, metadata);
                    Paths.iterateDirectory(Paths.mods(modDir), function(name:String){
                        var directory = Paths.mods(modDir + "/" + name);
                        if (FileSystem.isDirectory(directory)){
                            if (namespaceMap.get(name) == null)
                                namespaceMap.set(name, []);
                            
                            namespaceMap.get(name).push(modDir);
                        }
                    });
                }else{
                    trace("unknown content format");
                }
                
            }

			if (!is_new){
				var packJson:Dynamic = getJson(modDir + "/pack.json");
				if (metadataJson != null){
                    // its an old TE mod
					trace('${modDir} uses old TE metadata');
					var name = Reflect.field(metadataJson, "name");
					if (name == null)
						name = modDir;

					var metadata:ContentV3Metadata = {
						name: name, 
					    description:'Oh.. That\'s "$name"...',
                        version: "1.0.0",
                        credits: [],
                        requires_restart: false,
                        dependencies: [],
                        engine_version: ">=0.2.0",
                        content_format: 3
                    }
					contentMetadata.set(modDir, metadata);
					if (namespaceMap.get(modDir) == null)
						namespaceMap.set(modDir, []);

					namespaceMap.get(modDir).push(modDir);

                }else if(packJson != null){
                    // Psych mod
					trace('${modDir} uses psych pack.json');
                    var creditArray:Array<Array<String>> = [];
					var creditPath = Paths.mods(modDir + "/data/credits.txt");
					var rawTxt:Null<String> = Paths.getContent(creditPath);
					if (rawTxt != null && rawTxt.length > 0){
                        var daCredits = rawTxt.trim().split("\n");
						for (i in daCredits)
						{
							var arr:Array<String> = i.replace('\\n', '\n').split("::");
							creditArray.push([
                                arr[0], // name
                                arr[2], // desc
                                arr[3], // link
                                arr[1] // icon
                            ]);
						}
                    }

					var metadata:ContentV3Metadata = {
						name: packJson.name,
						description: packJson.description,
						version: "1.0.0",
						credits: creditArray,
						requires_restart: packJson.restart,
						dependencies: [],
						engine_version: ">=0.2.0",
						content_format: 3
					}
					contentMetadata.set(modDir, metadata);
                    if(Reflect.field(packJson, "runsGlobally"))
						namespaceMap.get("troll_engine").push(modDir);
                    else{
						if (namespaceMap.get(modDir) == null)
							namespaceMap.set(modDir, []);

						namespaceMap.get(modDir).push(modDir);
                    }
                }

				if (contentMetadata.get(modDir) == null){
                    // default behaviour
                    trace('$modDir isnt troll engine metadata OR psych pack.json lmao');
					var metadata:ContentV3Metadata = {
						name: modDir,
						description: 'Oh.. That\'s "$modDir"...',
						version: "1.0.0",
						credits: [],
						requires_restart: false,
						dependencies: [],
						engine_version: ">=0.2.0",
						content_format: 3
					}
					contentMetadata.set(modDir, metadata);
					if (namespaceMap.get(modDir) == null)
						namespaceMap.set(modDir, []);

					namespaceMap.get(modDir).push(modDir);
                }
            }

			loadedContent.push(modDir);
		}
        // TODO: sort w/ load order
    }
}