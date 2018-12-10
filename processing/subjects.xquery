import module namespace bod = "http://www.bodleian.ox.ac.uk/bdlss" at "https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc2solr.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option saxon:output "indent=yes";

<add>
{
    let $doc := doc("../authority/subjects.xml")
    let $collection := collection('../collections?select=*.xml;recurse=yes')
    let $subjects := $doc//tei:item[@xml:id]
    
    let $placekeys := distinct-values($collection//(tei:placeName|tei:name[@type='place'])/@key)

    for $subject in $subjects
    
        let $id := $subject/@xml:id/string()
        let $name := normalize-space($subject/tei:term[@type = 'display' or (@type = 'variant' and not(preceding-sibling::tei:term))]/string())
        let $isplace := boolean($id = $placekeys)
        let $islcsh := starts-with($id, 'subject_s')
        let $islcn := starts-with($id, 'subject_n')
        let $variants := $subject/tei:term[@type="variant"]
        let $noteitems := $subject/tei:note[@type="links"]//tei:item

        let $mss := $collection//tei:TEI[.//(tei:term|tei:placeName|tei:name[@type='place'])[@key = $id]]
        
        let $types := distinct-values((
                                        $mss//(tei:term|tei:placeName|tei:name[@type='place'])[@key = $id]/@role/tokenize(normalize-space(.), ' '), 
                                        if ($isplace) then 'Place' else (),
                                        if ($islcsh) then 'Library of Congress Subject Heading' else (),
                                        if ($islcn) then 'Library of Congress Name Authority' else ()
                                     ))

        return if (count($mss) > 0) then
        <doc>
            <field name="type">subject</field>
            <field name="pk">{ $id }</field>
            <field name="id">{ $id }</field>
            <field name="title">{ $name }</field>
            <field name="alpha_title">{  bod:alphabetize($name) }</field>
            <field name="sb_name_s">{ $name }</field>
            {
            if (count($types) > 0) then
                for $type in $types
                    order by $type
                    return <field name="sb_type_sm">{ $type }</field>
            else
                <field name="sb_type_sm">Not Specified</field>
            }
            {
            for $variant in $variants
                let $vname := normalize-space($variant/string())
                order by $vname
                return <field name="sb_variant_sm">{ $vname }</field>
            }
            {
            for $item in $noteitems
                let $refs := $item//tei:ref
                order by $refs[1]
                for $ref in $refs
                    let $linktarget := $ref/string(@target)
                    let $linktitle := $ref/normalize-space(tei:title/string())
                    let $linktext := if ($linktitle eq 'LC') then 'Library of Congress (authority record)' else $linktitle
                    order by $linktarget
                    return <field name="link_external_smni">{ concat($linktarget, "|", $linktext)}</field>
            }
            {
            for $ms in $mss
                let $msid := $ms/string(@xml:id)
                let $url := concat("/catalog/", $msid[1])
                let $classmark := $ms//tei:msDesc/tei:msIdentifier/tei:idno[1]/text()
                let $repository := normalize-space($ms//tei:msDesc/tei:msIdentifier/tei:repository[1]/text())
                let $institution := normalize-space($ms//tei:msDesc/tei:msIdentifier/tei:institution/text())
                let $linktext := concat(
                                    $classmark, 
                                    ' (', 
                                    $repository,
                                    if ($repository ne $institution) then
                                        concat(', ', translate(replace($institution, ' \(', ', '), ')', ''), ')')
                                    else
                                        ')'
                                )
                order by $institution, $classmark
                return <field name="link_manuscripts_smni">{ concat($url, "|", $linktext[1]) }</field>
            }
            {
                for $relatedid in distinct-values((tokenize(translate($subject/@corresp, '#', ''), ' '), tokenize(translate($subject/@sameAs, '#', ''), ' ')))
                    let $url := concat("/catalog/", $relatedid)
                    let $linktext := $doc//tei:list/tei:item[@xml:id = $relatedid]/tei:term[@type = 'display' or (@type = 'variant' and not(preceding-sibling::tei:term))][1]/string()
                    return
                    <field name="link_related_smni">{ concat($url, "|", $linktext) }</field>
                }
        </doc>
        else
            bod:logging('info', 'Skipping subject in authority file but not in any manuscript', ($id, $name))
}
</add>
