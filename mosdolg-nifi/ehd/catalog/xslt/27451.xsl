<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
                xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                xmlns:ehd="http://ehd.mos.com/"
                exclude-result-prefixes="env wsse ehd">

    <xsl:output method="xml" indent="no"/>

    <xsl:template match="/env:Envelope/env:Body/ehd:getCatalogItemsResponse/ehd:ehdCatalogItemsset">
        <ehdCatalogItemsset>
            <xsl:apply-templates/>
        </ehdCatalogItemsset>
    </xsl:template>

    <xsl:template match="ehd:ehdCatalogItem">
        <ehdCatalogItem>
            <xsl:for-each select="ehd:ehdCatalogAttr">
                <xsl:element name="{lower-case(ehd:tehName)}">
                    <xsl:value-of select="ehd:value/text()"/>
                </xsl:element>
            </xsl:for-each>
<!--            <xsl:element name="is_deleted">-->
<!--                <xsl:value-of select="ehd:ehdCatalogAttr/ehd:isDeleted/text()"/>-->
<!--            </xsl:element>-->
        </ehdCatalogItem>
    </xsl:template>
</xsl:stylesheet>