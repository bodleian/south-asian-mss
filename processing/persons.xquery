import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";


<add>
{
    let $doc := doc("../authority/persons.xml")
    let $collection := collection("../collections?select=*.xml;recurse=yes")
    let $people := $doc//tei:listPerson/tei:person

    for $person in $people
    
        let $id := $person/@xml:id/string()
        let $name := normalize-space($person//tei:persName[@type = 'display' or (@type = 'variant' and not(preceding-sibling::tei:persName))][1]/string())
        let $variants := $person/tei:persName[@type="variant"]
                
        let $mss := $collection//tei:TEI[.//(tei:persName|tei:author|tei:editor)[@key = $id]]
        
        return if (count($mss) gt 0) then 
            <doc>
                <field name="type">person</field>
                <field name="pk">{ $id }</field>
                <field name="id">{ $id }</field>
                <field name="title">{ $name }</field>
                <field name="alpha_title">{  bod:alphabetize($name) }</field>
                <field name="pp_name_s">{ $name }</field>
                {
                for $variant in $variants
                    let $vname := normalize-space($variant/string())
                    order by $vname
                    return <field name="pp_variant_sm">{ $vname }</field>
                }
                {
                let $isauthor := some $i in $mss//tei:author satisfies $i/@key = $id
                let $issubject := some $i in $mss//tei:title//tei:persName satisfies $i/@key = $id
                let $iseditor := some $i in $mss//tei:editor[not(@role)] satisfies $i/@key = $id
                let $roles := 
                    (
                    for $r in $mss//(tei:author|tei:editor|tei:persName)[@key = $id and @role]/@role return tokenize($r, ' '), 
                    if ($isauthor) then 'author' else (), 
                    if ($issubject) then 'subject of a work' else (),
                    if ($iseditor) then 'editor' else ()
                    )
                for $role in distinct-values($roles)
                    order by $role
                    return <field name="roles_sm">{ bod:personRoleLookup($role) }</field>
                }
                {
                for $ms in $mss
                    let $msid := $ms/@xml:id/string()
                    let $url := concat("/catalog/", $msid)
                    let $classmark := $ms//tei:msDesc/tei:msIdentifier/tei:idno[1]/text()
                    order by $classmark
                    return <field name="link_manuscripts_smni">{ concat($url, "|", $classmark) }</field>
                }
                {
                for $relatedid in distinct-values((tokenize(translate($person/@corresp, '#', ''), ' '), tokenize(translate($person/@sameAs, '#', ''), ' ')))
                    let $url := concat("/catalog/", $relatedid)
                    let $linktext := $doc//tei:listPerson/tei:person[@xml:id = $relatedid]/tei:persName[@type = 'display' or (@type = 'variant' and not(preceding-sibling::tei:persName))][1]/string()
                    return
                    <field name="link_related_smni">{ concat($url, "|", $linktext) }</field>
                }
            </doc>
        else
            ()
}

</add>

