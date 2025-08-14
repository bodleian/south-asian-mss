<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:bod="http://www.bodleian.ox.ac.uk/bdlss"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei html xs bod"
    version="2.0">
    
    

    <!-- The stylesheet is a library. It doesn't validate and won't produce HTML on its own. It is called by 
         convert2HTML.xsl and previewManuscript.xsl. Any templates added below will override the templates 
         in msdesc2html.xsl in the consolidated-tei-schema repository, allowing customization of manuscript 
         display for each catalogue. -->

    <xsl:template match="msItemStruct">
        <xsl:apply-templates/>
        <xsl:if test="@class">
            <div class="{name()}">
                <span class="tei-label">
                    <xsl:copy-of select="bod:standardText('Class:')"/>
                    <xsl:text> </xsl:text>
                </span>
                <xsl:value-of select="@class"/>
            </div> 
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="msItem">
        <xsl:apply-templates/>
        <xsl:if test="@class">
            <div class="{name()}">
                <span class="tei-label">
                    <xsl:copy-of select="bod:standardText('Class:')"/>
                    <xsl:text> </xsl:text>
                </span>
                <xsl:value-of select="@class"/>
            </div> 
        </xsl:if>
    </xsl:template>
    
    

    
    <xsl:template match="msItemStruct/textLang">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Language(s):')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:choose>
                <xsl:when test="not(.//text()) and (@mainLang or @otherLangs)">
                    <xsl:for-each select="tokenize(string-join((@mainLang, @otherLangs), ' '), ' ')">
                        <xsl:value-of select="bod:languageCodeLookup(.)"/>
                        <xsl:if test="position() ne last()"><xsl:text>, </xsl:text></xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    

    <!-- Append the calendar if it does not appear to have been mentioned in the origDate text -->
    <xsl:template match="origDate[@calendar]">
        <span class="{name()}">
            <xsl:apply-templates/>
            <xsl:choose>
                <xsl:when test="@calendar = ('#Hijri-qamari', 'Hijri-qamari') and not(matches(string-join(.//text(), ''), '[\d\s](H|AH|A\.H|Hijri)'))">
                    <xsl:text> AH</xsl:text>
                </xsl:when>
                <xsl:when test="@calendar = ('#Gregorian', 'Gregorian') and not(matches(string-join(.//text(), ''), '[\d\s](CE|AD|C\.E|A\.D|Gregorian)'))">
                    <xsl:text> CE</xsl:text>
                </xsl:when>
            </xsl:choose>
        </span>
        <xsl:variable name="nextelem" select="following-sibling::*[1]"/>
        <xsl:if test="following-sibling::*[self::origDate] and not(following-sibling::node()[1][self::text()][string-length(normalize-space(.)) gt 0])">
            <!-- Insert a semi-colon between adjacent dates without text between them -->
            <xsl:text>; </xsl:text>
        </xsl:if>
    </xsl:template>
    
  
    <xsl:template match="msItemStruct/title">
        <div class="tei-title">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Title:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:variable name="keys" select="tokenize(@key, '\s+')[string-length(.) gt 0]"/>
            <xsl:choose>
                <xsl:when test="some $key in $keys satisfies starts-with($key, 'work_')">
                    <xsl:variable name="key" select="$keys[starts-with(., 'work_')][1]"/>
                    <a>
                        <xsl:if test="not(@type = 'desc')">
                            <xsl:attribute name="class" select="'italic'"/>
                        </xsl:if>
                        <xsl:attribute name="href">
                            <xsl:value-of select="$website-url"/>
                            <xsl:text>/catalog/</xsl:text>
                            <xsl:value-of select="$key"/>
                        </xsl:attribute>
                        <xsl:copy-of select="bod:direction(.)"/>
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <span>
                        <xsl:if test="not(@type = 'desc')">
                            <xsl:attribute name="class" select="'italic'"/>
                        </xsl:if>
                        <xsl:copy-of select="bod:direction(.)"/>
                        <xsl:apply-templates/>
                    </span>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>



    <!-- Prevent facs attributes from being displayed. Move to msdesc2html.xsl? -->
    <xsl:template match="@facs"/>


    
    <!-- Do not display places as hyperlinks if the key is not a subject -->
    <xsl:template match="placeName[not(starts-with(@key, 'subject_'))] | name[@type='place'][not(starts-with(@key, 'subject_'))]">
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="string-join((name(), @role), ' ')"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <!-- only display one type of name, and prefer display over standard -->
    <xsl:template match="persName[@type='standard'][following-sibling::persName[@type='display']]"/>
    

    

    <!-- Per Camillo's instructions, see https://github.com/bodleian/south-asian-mss/issues/2 -->
    <xsl:template match="tei:g">
        <xsl:choose>
            <xsl:when test="text() = '%'">
                <xsl:text>&#x25CE;</xsl:text>
            </xsl:when>
            <xsl:when test="text() = '@'">
                <xsl:text>&#x2740;</xsl:text>
            </xsl:when>
            <xsl:when test="text() = '$'">
                <xsl:text>&#x2240;</xsl:text>
            </xsl:when>
            <xsl:when test="text() = 'bhale'">
                <xsl:text>&#x2114;</xsl:text>
            </xsl:when>
            <xsl:when test="text() = ','">
                <xsl:text>&#x0027;</xsl:text>
            </xsl:when>
            <xsl:when test="text() = '§'">
                <xsl:text>&#x30FB;</xsl:text>
            </xsl:when>
            <xsl:when test="text() = 'ba'">
                <xsl:text>&#x00A7;</xsl:text>
            </xsl:when>
            <xsl:when test="text() = '*'">
                <xsl:text>*** TODO ***</xsl:text>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:value-of select="text()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    
</xsl:stylesheet>
