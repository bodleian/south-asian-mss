<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns:jc="http://james.blushingbunny.net/ns.html" exclude-result-prefixes="tei jc" version="2.0">

  <!-- 
  Created by James Cummings james@blushingbunny.net 
  2017-07 or so
  for up-conversion of existing TEI  Fihrist Catalogue
  -->

<!-- loading in common-mss.xsl for general stuff catalogue specific stuff below
     but hope is that most things will be common -->

<!--the original common-mss.xsl is at https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/common-mss.xsl -->
<xsl:import href="../../common-mss.xsl"/>

  <!-- variable for overall collection -->
  <xsl:variable name="cat" select="'Tibetan'"/>
  <xsl:variable name="catdir" select="'tibetan'"/>

  <xsl:template match="msDesc/msIdentifier/idno">
    <idno><xsl:value-of select="replace(., '\.', '. ')"/></idno>
</xsl:template>
  

  <xsl:function name="jc:normalizeID">
    <xsl:param name="id" as="item()"/>
    <xsl:variable name="ID">
      <xsl:value-of select="replace($id, '\.', '. ')"/>
    </xsl:variable>
    <xsl:variable name="pass0">
      <xsl:choose>
        <!-- some idno have a 12.3 type format -->
        <xsl:when test="matches($ID, '[0-9]\.[0-9]')">
          <xsl:variable name="part">
            <xsl:analyze-string select="$ID" regex="([a-zA-Z]+)\.">
              <xsl:matching-substring><xsl:value-of select="regex-group(1)"/></xsl:matching-substring>
              <xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
            </xsl:analyze-string>
          </xsl:variable>
          <xsl:value-of select="translate(normalize-space($part), '`!£$%^[_]°()}{,', '')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="translate(normalize-space($ID), '`!£$%^[_]°()}{,.', '')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="pass1">
      <xsl:value-of select="replace(normalize-space($pass0), ' - ', '-')"/>
    </xsl:variable>
    <xsl:variable name="pass2">
      <xsl:value-of select="replace(normalize-space($pass1), '\*', '-star')"/>
    </xsl:variable>
    <xsl:variable name="apos">&apos;</xsl:variable>
    <xsl:variable name="pass3">
      <xsl:value-of select="replace(normalize-space($pass2), $apos, '')"/>
    </xsl:variable>
    <xsl:value-of select="translate(normalize-space($pass3), ' \/','_..')"/>
  </xsl:function>

</xsl:stylesheet>
