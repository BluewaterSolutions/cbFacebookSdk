component {

    public function init(){
        return this;
    }

    public function removeParamsFromUrl( url, array paramsToFilter ){

        if( !len( arguments.url ) ){
            return "";
        }
        var parts = parseUrl( arguments.url );

        var query = "";
        if ( structKeyExists(parts, 'params' ) ){

            for( k in arguments.paramsToFilter ){
                if( structKeyExists(parts.params.url, k) ){
                    structDelete( parts.params.url, k );
                }
            }

            if ( StructCount( parts.params.url ) > 0 ) {
                query = '?' & serializeQueryString( parts.params.url );
            }
        }
        var scheme = len( parts['scheme'] ) ? parts['scheme'] & '://' : '';
        var host = len( parts['host'] ) ? parts['host'] : '';
        var port = len( parts['port'] ) ? ':' & parts['port'] : '';
        var path = len( parts['path'] ) ? parts['path'] : '';
        var fragment = len( parts['fragment'] ) ? '##' & parts['fragment'] : '';

        return scheme & host & port & path & query & fragment;

    }

    public function getParamsAsStruct( url ){
        var queryString = parseUrl( arguments.url )['query'];
        return queryString;
    }

    private function parseUrl( sUrl ){
        // var to hold the final structure
        var stUrlInfo = structNew();
        // var to hold the final structure
        var sCharSet = getEncoding("url");
        // vars for use in the loop, so we don't have to evaluate lists and arrays more than once
        var i = 1;
        var sKeyPair = "";
        var sKey = "";
        var sValue = "";
        var aQSPairs = "";
        var sPath = "";
        /*
            from: http://www.ietf.org/rfc/rfc2396.txt

            ^((([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*)))?
             123 4 5 6 7 8 9 A

                scheme = $3
                authority = $5
                path = $6
                query = $8
                fragment = $10 (A)
        */
        var sUriRegEx = "^(([^:/?##]+):)?(//([^/?##]*))?([^?##]*)(\?([^##]*))?(##(.*))?";
        /*
            separates the authority into user info, domain and port

            ^((([^@:]+)(:([^@]+))?@)?([^:]*)?(:(.*)))?
             123 4 5 6 7 8

                username = $3
                password = $5
                domain = $6
                port = $8
        */
        var sAuthRegEx = "^(([^@:]+)(:([^@]+))?@)?([^:]*)?(:(.*))?";
        /*
            separates the path into segments & parameters

            ((/?[^;/]+)(;([^/]+))?)
            12 3 4

                segment = $1
                path = $2
                parameters = $4
        */
        var sSegRegEx = "(/?[^;/]+)(;([^/]+))?";

        // parse the url looking for info
        var stUriInfo = reFindNoCase(sUriRegEx, arguments.sUrl, 1, true);
        // this is for the authority section
        var stAuthInfo = "";
        // this is for the segments in the path
        var stSegInfo = "";

        // if the charset argument exists, use it -- this defaults to the url encoding to mimic the default
        // behavior
        if( arrayLen(arguments) gte 2 ) sCharSet = arguments[2];

        // create empty keys
        stUrlInfo["scheme"] = "";
        stUrlInfo["authority"] = "";
        stUrlInfo["path"] = "";
        stUrlInfo["directory"] = "";
        stUrlInfo["file"] = "";
        stUrlInfo["query"] = "";
        stUrlInfo["fragment"] = "";
        stUrlInfo["host"] = "";
        stUrlInfo["port"] = "";
        stUrlInfo["username"] = "";
        stUrlInfo["password"] = "";
        stUrlInfo["params"] = structNew();

        // get the scheme
        if( stUriInfo.len[3] gt 0 ) stUrlInfo["scheme"] = mid(arguments.sUrl, stUriInfo.pos[3], stUriInfo.len[3]);
        // get the authority
        if( stUriInfo.len[5] gt 0 ) stUrlInfo["authority"] = mid(arguments.sUrl, stUriInfo.pos[5], stUriInfo.len[5]);
        // get the path
        if( stUriInfo.len[6] gt 0 ) stUrlInfo["path"] = mid(arguments.sUrl, stUriInfo.pos[6], stUriInfo.len[6]);
        // get the path
        if( stUriInfo.len[8] gt 0 ) stUrlInfo["query"] = mid(arguments.sUrl, stUriInfo.pos[8], stUriInfo.len[8]);
        // get the fragment
        if( stUriInfo.len[10] gt 0 ) stUrlInfo["fragment"] = mid(arguments.sUrl, stUriInfo.pos[10], stUriInfo.len[10]);

        // break authority into user info, domain and ports
        if( len(stUrlInfo["authority"]) gt 0 ){
            // parse the authority looking for info
            stAuthInfo = reFindNoCase(sAuthRegEx, stUrlInfo["authority"], 1, true);

            // get the domain
            if( stAuthInfo.len[6] gt 0 ) stUrlInfo["host"] = mid(stUrlInfo["authority"], stAuthInfo.pos[6], stAuthInfo.len[6]);
            // get the port
            if( stAuthInfo.len[8] gt 0 ) stUrlInfo["port"] = mid(stUrlInfo["authority"], stAuthInfo.pos[8], stAuthInfo.len[8]);
            // get the username
            if( stAuthInfo.len[3] gt 0 ) stUrlInfo["username"] = mid(stUrlInfo["authority"], stAuthInfo.pos[3], stAuthInfo.len[3]);
            // get the password
            if( stAuthInfo.len[5] gt 0 ) stUrlInfo["password"] = mid(stUrlInfo["authority"], stAuthInfo.pos[5], stAuthInfo.len[5]);
        }

        // the query string in struct form
        stUrlInfo["params"]["segment"] = structNew();

        // if the path contains any parameters, we need to parse them out
        if( find(";", stUrlInfo["path"]) gt 0 ){
            // this is for the segments in the path
            stSegInfo = reFindNoCase(sSegRegEx, stUrlInfo["path"], 1, true);

            // loop through all the segments and build the strings
            while( stSegInfo.pos[1] gt 0 ){
                // build the path, excluding parameters
                sPath = sPath & mid(stUrlInfo["path"], stSegInfo.pos[2], stSegInfo.len[2]);

                // if there are some parameters in this segment, add them to the struct
                if( stSegInfo.len[4] gt 0 ){

                    // put the parameters into an array for easier looping
                    aQSPairs = listToArray(mid(stUrlInfo["path"], stSegInfo.pos[4], stSegInfo.len[4]), ";");

                    // now, loop over the array and build the struct
                    for( i=1; i lte arrayLen(aQSPairs); i=i+1 ){
                        sKeyPair = aQSPairs[i]; // current pair
                        sKey = listFirst(sKeyPair, "="); // current key
                        // make sure there are 2 keys
                        if( listLen(sKeyPair, "=") gt 1){
                            sValue = listLast(sKeyPair, "="); // current value
                            // fix bug in urlDecode w/single % signs
                            sValue = reReplaceNoCase(sValue, "%([^A-F0-9{2}])", "%25\1", "all");
                            // url decode the value
                            sValue = urlDecode(sValue, sCharSet);
                        } else {
                            sValue = ""; // set blank value
                        }
                        // check if key already added to struct
                        if( structKeyExists(stUrlInfo["params"]["segment"], sKey) ) stUrlInfo["params"]["segment"][sKey] = listAppend(stUrlInfo["params"]["segment"][sKey], sValue); // add value to list
                        else structInsert(stUrlInfo["params"]["segment"], sKey, sValue); // add new key/value pair
                    }
                }

                // get the ending position
                i = stSegInfo.pos[1] + stSegInfo.len[1];

                // get the next segment
                stSegInfo = reFindNoCase(sSegRegEx, stUrlInfo["path"], i, true);
            }

        } else {
            // set the current path
            sPath = stUrlInfo["path"];
        }

        // get the file name
        stUrlInfo["file"] = getFileFromPath(sPath);
        // get the directory path by removing the file name
        if( len(stUrlInfo["file"]) gt 0 ){
            stUrlInfo["directory"] = replace(sPath, stUrlInfo["file"], "", "one");
        } else {
            stUrlInfo["directory"] = sPath;
        }

        // the query string in struct form
        stUrlInfo["params"]["url"] = structNew();

        // if query info was supplied, break it into a struct
        if( len(stUrlInfo["query"]) gt 0 ){
            // put the query string into an array for easier looping
            aQSPairs = listToArray(stUrlInfo["query"], "&");

            // now, loop over the array and build the struct
            for( i=1; i lte arrayLen(aQSPairs); i=i+1 ){
                sKeyPair = aQSPairs[i]; // current pair
                sKey = listFirst(sKeyPair, "="); // current key
                // make sure there are 2 keys
                if( listLen(sKeyPair, "=") gt 1){
                    sValue = urlDecode(listLast(sKeyPair, "=")); // current value
                } else {
                    sValue = ""; // set blank value
                }
                // check if key already added to struct
                if( structKeyExists(stUrlInfo["params"]["url"], sKey) ) stUrlInfo["params"]["url"][sKey] = listAppend(stUrlInfo["params"]["url"][sKey], sValue); // add value to list
                else structInsert(stUrlInfo["params"]["url"], sKey, sValue); // add new key/value pair
            }
        }

        // return the struct
        return stUrlInfo;
    }

    public function forceSlashPrefix( string ){
        if (!len(arguments.string)) {
            return arguments.string;
        }
        return left(arguments.string,1) EQ "/" ? arguments.string : '/' & arguments.string;
    }

    public function appendParamsToUrl(url, struct newParams ){
        if ( structIsEmpty( arguments.newParams ) ){
            return arguments.url;
        }

        if( !Find( "?", arguments.url ) ){
            return arguments.url & '?' & serializeQueryString( arguments.newParams );
        }

        var parts = parseUrl( arguments.url );
        var qStr = "";

        for (key in arguments.newParams) {
            qStr = ListAppend(qStr, key & "=" & arguments.newParams[key], "&");
        }

        return arguments.url & "&" & qStr;

    }

    public String function serializeQueryString(required Struct parameters, Boolean urlEncoded = true) {
        var queryString = "";
        for (var key in arguments.parameters) {
            if (queryString != "") {
                queryString = queryString  & "&";
            }
            if (arguments.urlEncoded) {
                queryString = queryString & LCase(key) & "=" & urlEncodedFormat(arguments.parameters[key]);
            } else {
                queryString = queryString & LCase(key) & "=" & arguments.parameters[key];
            }
        }
        return queryString;
    }

}