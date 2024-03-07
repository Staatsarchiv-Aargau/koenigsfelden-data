xquery version "3.1";

module namespace idx="http://teipublisher.com/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dbk="http://docbook.org/ns/docbook";

declare variable $idx:app-root :=
    let $rawPath := system:get-module-load-path()
    return
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    ;

(:~
 : Helper function called from collection.xconf to create index fields and facets.
 : This module needs to be loaded before collection.xconf starts indexing documents
 : and therefore should reside in the root of the app.
 :)
declare function idx:get-metadata($root as element(), $field as xs:string) {
    let $header := $root/tei:teiHeader
    return
        switch ($field)
            case "title" return head($header/descendant::tei:title)
            case "regest" return $header/descendant::tei:msContents/tei:summary
            case "comment" return $root/descendant::tei:back
            case "notes" return $root/descendant::tei:body/descendant::tei:note | $root/descendant::tei:back/descendant::tei:note
            case "seal" return $header/descendant::tei:physDesc/descendant::tei:seal
            case "edition" return $root/descendant::tei:body
            case "author" return (
                $header//tei:correspDesc/tei:correspAction/tei:persName,
                $header//tei:titleStmt/tei:author
            )
            case "language" return $header/descendant::tei:textLang
                
            case "date" return head((
                $header//descendant::tei:origDate/@when,
                $header//descendant::tei:origDate/@from
            ))
            case "max-date" return head((
                $header//descendant::tei:origDate/@to,
                $header//descendant::tei:origDate/@when
            ))
            case "min-date" return head((
                $header//descendant::tei:origDate/@from,
                $header//descendant::tei:origDate/@when
            ))
            case "genre" return (
                idx:get-genre($header),
                $root/dbk:info/dbk:keywordset[@vocab="#genre"]/dbk:keyword
            )
            case "material" return $header/descendant::tei:physDesc/descendant::tei:material
            case "keywords" return $header/descendant::tei:keywords/tei:term
            default return
                ()
};

declare function idx:get-genre($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#genre"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};

declare function idx:get-collection($file as xs:string, $type as xs:string) {
    let $index := doc($idx:app-root || '/' || $type || '.xml')
    return 
        $index//document[. = $file]/parent::collection/@ref
    
    };
    
declare function idx:get-mentions($text as element(), $type as xs:string) {
    switch ($type)
        case 'person' return $text/descendant::tei:persName/@ref
        case 'place' return $text/descendant::tei:placeName/@ref
        case 'org' return $text/descendant::tei:orgName/@ref
        case 'keyword' return $text/tei:teiHeader/descendant::tei:term
        default return ()
    };
