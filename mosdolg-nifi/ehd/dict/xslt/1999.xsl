<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                xmlns:ehd="http://ehd.mos.com/"
                exclude-result-prefixes="env wsse ehd">

    <xsl:output method="xml" indent="no"/>

    <xsl:template match="/env:Envelope/env:Body/ehd:getDictItemV2Response/ehd:ehdDictionaryItemsV2">
        <ehdDictionaryItemV2>
            <xsl:apply-templates/>
        </ehdDictionaryItemV2>
    </xsl:template>

    <xsl:template match="ehd:ehdDictionaryItemV2">
        <ehdDictionaryItemV2>
            <xsl:element name="id"><xsl:value-of select="ehd:id/text()"/></xsl:element>
            <xsl:element name="parent_id"><xsl:value-of select="ehd:parent_id/text()"/></xsl:element>
            <xsl:element name="name"><xsl:value-of select="ehd:name/text()"/></xsl:element>
            <xsl:for-each select="ehd:dictAttrsV2">
                <xsl:element name="{lower-case(ehd:tehName)}">
                    <xsl:value-of select="ehd:value/text()"/>
                </xsl:element>
            </xsl:for-each>
        </ehdDictionaryItemV2>
    </xsl:template>

</xsl:stylesheet>
