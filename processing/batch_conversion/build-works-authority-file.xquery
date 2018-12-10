declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace saxon="http://saxon.sf.net/";
declare option saxon:output "indent=yes";

declare function local:logging($level, $msg, $values)
{
    (: Trick XQuery into doing trace() to output message to STDERR but not insert it into the XML :)
    substring(trace('', concat(upper-case($level), '	', $msg, '	', string-join($values, '	'), '	')), 0, 0)
};

declare function local:normalize4Crossrefing($title as xs:string) as xs:string
{
    let $normalized1 := replace($title, '^(the|a|an) ', '', 'i')
    let $normalized2 := 
        translate(
            translate(
                replace(
                    replace(
                        replace(
                            lower-case($normalized1), 
                            '[^\p{L}\d]', ''
                        ),
                    'æ', 'ae'),
                'œ', 'oe'),
            'ṅźśñāūṃḷīü', 'nzsnaumliu'),
        'ʼ', '')
    let $normalized3 := replace(replace(replace(replace(replace($normalized2, "[ʻ’'ʻ‘ʺʹʾ]" ,""), 'ʻ̐', ''), 'ʹ̨', ''), 'ʻ̨', ''), '"', '')
    return $normalized3
};

processing-instruction xml-model {'href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" schamtypens="http://relaxng.org/ns/structure/1.0"'},
processing-instruction xml-model {'href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" schamtypens="http://purl.oclc.org/dsdl/schematron"'},
processing-instruction xml-model {'href="authority-schematron.sch" type="application/xml" schamtypens="http://purl.oclc.org/dsdl/schematron"'},
<TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>Title</title>
            </titleStmt>
            <publicationStmt>
                <p>Publication Information</p>
            </publicationStmt>
            <sourceDesc>
                <p>Information about the source</p>
            </sourceDesc>
        </fileDesc>
    </teiHeader>
    <text>
        <body>
            <listBibl>
{

    let $collection := collection('../../collections/?select=*.xml;recurse=yes')
    let $linebreak := '&#10;&#10;'
    let $notitletitles := ()
    
    (: First, extract all title from identifiable works in the TEI files and build in-memory XML structure, 
       doing some string manipulations to anticipate potential different versions of the same title :)
    
    let $allworks as element()* := (
    
        for $msitem in $collection//tei:msItem[@xml:id]
            let $titles as xs:string* := (for $t in $msitem/title[not(@type='alt')] return normalize-space(string-join($t//text(), ' ')))[string-length(.) gt 0][not(. = $notitletitles)]
            let $alttitles as xs:string* := (for $t in $msitem/title[@type='alt'] return normalize-space(string-join($t//text(), ' ')))[string-length(.) gt 0][not(. = $notitletitles)]
            return
            if (count($titles) eq 0 and not($msitem/tei:author) and string-length($msitem/@class) gt 0) then
                let $title := concat('Untitled ', lower-case(normalize-space($msitem/@class)))
                return
                <work>
                    <title n="{ $msitem/@n }">{ $title }</title>
                    <norm>{ local:normalize4Crossrefing($title) }</norm>
                    <ref>{ concat(substring-after(base-uri($msitem), 'collections/'), '#', $msitem/@xml:id) }</ref>
                </work>
            else if (count($titles) eq 0 and $msitem/tei:author[string-length(normalize-space(string-join(.//text(), ''))) gt 0]) then
                let $title := concat('Untitled work by ', normalize-space(string-join($msitem/tei:author[1]/tei:persName[1]/text(), ' ')))
                return  
                <work>
                    <title n="{ $msitem/@n }">{ $title }</title>
                    <norm>{ local:normalize4Crossrefing($title) }</norm>
                    <ref>{ concat(substring-after(base-uri($msitem), 'collections/'), '#', $msitem/@xml:id) }</ref>
                </work>
            else
                (: In Karchak there are occassionally multiple titles in individual works :)
                <work>
                    {
                    for $title in $titles
                        return (
                        <title n="{ $msitem/@n }">{ $title }</title>
                        ,
                        <norm>{ local:normalize4Crossrefing($title) }</norm>
                        )
                    }
                    {
                    for $title in $alttitles
                        return
                        (
                        <alt n="{ $msitem/@n }">{ $title }</alt>
                        ,
                        <norm>{ local:normalize4Crossrefing($title) }</norm>
                        )
                    
                    }
                    <ref>{ concat(substring-after(base-uri($msitem), 'collections/'), '#', $msitem/@xml:id) }</ref>
                </work>
    )
    
    (: Now de-duplicate, generating keys, and putting the titles in alphabetical order :)
    
    let $dedupedworks := (
    
        for $t at $pos in distinct-values($allworks//title)
            order by lower-case($t)
            let $variations := distinct-values(($t, $allworks[title = $t]/norm))
            let $variationsofvariations := distinct-values(($variations, $allworks[title = $variations or norm = $variations]/(title|norm)))
            let $variants := for $n in distinct-values(($t, $allworks[title = $variationsofvariations or norm = $variationsofvariations]/title)) order by $n return $n
            return
            if (count($variants) gt 1) then
            
                (: This title matches a variation of a title elsewhere, or it has a variation that 
                   matches another title, so pick this one if it comes first alphabetically :)
                
                if (index-of($variants, $t) eq 1) then
                    <bibl xml:id="{ concat('work_', $pos) }">
                        <title type="uniform">{ $t }</title>
                        {
                        for $a in subsequence($variants, 2)
                            return
                            <title type="variant">{ $a }</title>
                        }
                        {
                        for $a in distinct-values($allworks[title = $variationsofvariations or norm = $variationsofvariations]/alt)
                            return
                            <title type="variant">{ $a }</title>
                        }
                        {
                        for $r in distinct-values($allworks[title = $variants]/ref)
                            order by $r
                            return
                            comment{concat(' ../collections/', replace($r, '\-', '%2D'), ' ')}
                        }
                    </bibl>
                else
                    ()                  
            else
            
                (: There are no variants of this title :)
                <bibl xml:id="{ concat('work_', $pos) }">
                    <title type="uniform">{ $t }</title>
                    {
                    for $r in distinct-values($allworks[title = $t]/ref)
                        order by $r
                        return
                        comment{concat(' ../collections/', replace($r, '\-', '%2D'), ' ')}
                    }
                </bibl>
    )
    
    (: Output the authority file. The titles of type "crossref" are for cross-referencing in 
       the future, when updating the authority file for new works, and won't be indexed. :)
    for $b in $dedupedworks
        return
        (
        $linebreak,
        <bibl xml:id="{ $b/@xml:id }">
            { $b/title }
            { $b/comment() }
        </bibl>
        )
}
            </listBibl>
        </body>
    </text>
</TEI>




        
