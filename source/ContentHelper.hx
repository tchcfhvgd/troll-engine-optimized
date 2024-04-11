package;

// Class to help with loading content and getting data from them


class ContentHelper {
	public static var loadedContentDirectories:Array<String> = [];
    public static var loadedContent:Array<String> = [];
    public static var namespaceMap:Map<String, Array<String>> = []; // namespace => [contentWithNamespace], used to speed up lookups

    public static function loadContent(){
        loadedContent = [];

		for (modDir in Paths.getModDirectories(false))
		{
            // TODO: check if its enabled
			loadedContent.push(modDir);
		}
        // TODO: sort w/ load order
    }
}