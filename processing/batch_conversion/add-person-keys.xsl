<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="xs tei"
	version="2.0">

	<xsl:output method="xml" encoding="UTF-8"/>

	<xsl:variable name="newline" select="'&#10;'"/>
    
	<xsl:variable name="people" select="document('../../authority/persons_base.xml')//tei:TEI/tei:text/tei:body/tei:listPerson/tei:person"/>
	
	<xsl:template match="/">
	    <xsl:apply-templates/>
	    <xsl:value-of select="$newline"/>
	</xsl:template>
    
    <!-- The following templates do the first pass -->
    
    <xsl:template match="processing-instruction('xml-model')">
        <xsl:value-of select="$newline"/>
        <xsl:copy/>
        <xsl:if test="preceding::processing-instruction('xml-model')"><xsl:value-of select="$newline"/></xsl:if>
    </xsl:template>
    
    <xsl:template match="text()|comment()|processing-instruction()">
        <xsl:copy/>
    </xsl:template>
    
    <xsl:template match="*"><xsl:copy><xsl:copy-of select="@*"/><xsl:apply-templates/></xsl:copy></xsl:template>

    <xsl:template match="tei:author[not(ancestor::tei:titleStmt)] | tei:editor | tei:persName[not(ancestor::tei:author or ancestor::tei:editor or ancestor::tei:revisionDesc)]">
		<xsl:copy>
			<xsl:copy-of select="@*[not(name()='key')]"/>
		    <xsl:choose>
		        <xsl:when test="child::tei:persName">
		            <xsl:variable name="names" as="xs:string*" select="tei:persName/text()"/>
		            <xsl:if test="every $name in $names satisfies normalize-space($name) = $people/tei:persName/text()">
		                <xsl:attribute name="key" select="$people[tei:persName/text() = $names[1]]/@xml:id"/>
		            </xsl:if>
		        </xsl:when>
		        <xsl:otherwise>
		            <xsl:variable name="name" select="normalize-space(text())"/>
		            <xsl:if test="$name = $people/tei:persName/text()">
		                <xsl:attribute name="key" select="$people[tei:persName/text() = $name]/@xml:id"/>
		            </xsl:if>
		        </xsl:otherwise>
		    </xsl:choose>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>

    <xsl:template match="tei:persName[(ancestor::tei:author or ancestor::tei:editor) and preceding-sibling::*[1]/self::tei:persName]">
        <xsl:if test="count(preceding-sibling::tei:persName) eq 1">
            <xsl:text> (</xsl:text>
        </xsl:if>
        <xsl:copy><xsl:copy-of select="@*"/><xsl:apply-templates/></xsl:copy>
        <xsl:choose>
            <xsl:when test="not(following-sibling::tei:persName)">
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> / </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

</xsl:stylesheet>