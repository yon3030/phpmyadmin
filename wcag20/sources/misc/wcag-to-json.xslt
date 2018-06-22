<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:wcag="http://www.w3.org/WAI/GL/WCAG20/"
	exclude-result-prefixes="xs"
	version="2.0">
	
	<xsl:import href="../xmlspec-wcag.xsl"/>
	<xsl:param name="understanding.file">../guide-to-wcag2-src.xml</xsl:param>
	<xsl:param name="techniques.file">../wcag20-merged-techs.xml</xsl:param>
	
	<xsl:param name="understanding.doc" select="document($understanding.file)"/>
	<xsl:param name="techniques.doc" select="document($techniques.file)"/>
	
	<xsl:output method="text"/>
	
	<xsl:function name="wcag:json-string" as="xs:string">
		<xsl:param name="val"/>
		<xsl:variable name="string">
			<xsl:choose>
				<xsl:when test="string($val) = $val">
					<xsl:copy-of select="$val"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="$val"/>					
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="replace(normalize-space($string), '&quot;', '\\&quot;')"/>
	</xsl:function>
	
	<xsl:template match="text()">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="/">
		<xsl:text>{</xsl:text>
		<xsl:text>"principles": [</xsl:text>
		<xsl:apply-templates select="//div2[@role='principle']"></xsl:apply-templates>
		<xsl:text>]</xsl:text>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="div2[@role='principle']">
		<xsl:text>{</xsl:text>
		<xsl:text>"id": "WCAG2:</xsl:text><xsl:value-of select="@id"/><xsl:text>",</xsl:text>
		<xsl:text>"num": "</xsl:text><xsl:number/><xsl:text>",</xsl:text>
		<xsl:text>"handle": "</xsl:text>
		<!-- principle handles not usefully in the XML or imported XSLT, so manually outputting here -->
		<xsl:choose>
			<xsl:when test="@id='perceivable'">Perceivable</xsl:when>
			<xsl:when test="@id='operable'">Operable</xsl:when>
			<xsl:when test="@id='understandable'">Understandable</xsl:when>
			<xsl:when test="@id='robust'">Robust</xsl:when>
		</xsl:choose>
		<xsl:text>",</xsl:text><!-- requested key was title -->
		<xsl:text>"title": "</xsl:text><xsl:value-of select="wcag:json-string(head)"/><xsl:text>",</xsl:text><!-- full text of the principle, not in the requested key -->

		<xsl:text>"guidelines": [</xsl:text>
		<xsl:apply-templates select="div3[@role='group1']"></xsl:apply-templates>
		<xsl:text>]</xsl:text>

		<xsl:text>}&#10;</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="div3[@role='group1']">
		<xsl:variable name="handle">
			<xsl:call-template name="sc-handle">
				<xsl:with-param name="handleid" select="@id"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:text>{</xsl:text>
		<xsl:text>"id": "WCAG2:</xsl:text><xsl:value-of select="@id"/><xsl:text>",</xsl:text>
		<xsl:text>"num": "</xsl:text><xsl:number level="multiple" count="div2[@role='principle'] | div3" format="1.1"/><xsl:text>",</xsl:text>
		<xsl:text>"handle": "</xsl:text><xsl:value-of select="wcag:json-string($handle)"/><xsl:text>",</xsl:text><!-- requested key was title -->
		<xsl:text>"title": "</xsl:text><xsl:value-of select="wcag:json-string(head)"/><xsl:text>",</xsl:text><!-- requested key was intro -->

		<xsl:text>"techniques": [</xsl:text>
		<xsl:apply-templates select="$understanding.doc//*[@id = current()/@id]//*[@role = 'gladvisory']"></xsl:apply-templates>
		<xsl:text>],</xsl:text>

		<xsl:text>"successcriteria": [</xsl:text>
		<xsl:apply-templates select="div4/div5[@role = 'sc']"></xsl:apply-templates>
		<xsl:text>]</xsl:text>

		<xsl:text>}&#10;</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="div5[@role = 'sc']">
		<xsl:variable name="sc">
			<xsl:apply-templates select="p[@role = 'i' or @role = 'v']" mode="sc-text"/>
		</xsl:variable>
		<xsl:text>{</xsl:text>
		<xsl:text>"id": "WCAG2:</xsl:text><xsl:value-of select="@id"/><xsl:text>",</xsl:text>
		<xsl:text>"num": "</xsl:text><xsl:number level="multiple" count="div2[@role='principle'] | div3 | div5" format="1.1.1"/><xsl:text>",</xsl:text>
		<xsl:text>"level": "</xsl:text><xsl:call-template name="sc-level"/><xsl:text>",</xsl:text>
		<xsl:text>"handle": "</xsl:text><xsl:value-of select="wcag:json-string(head)"/><xsl:text>",</xsl:text><!-- requested key was title -->
		<xsl:text>"text": "</xsl:text><xsl:value-of select="wcag:json-string(string($sc))"/><xsl:text>",</xsl:text>
		<xsl:if test="p/following-sibling::*">
			<xsl:text>"details": [</xsl:text>
			<xsl:apply-templates select="p/following-sibling::*" mode="sc-details"/>
			<xsl:text>],</xsl:text>
		</xsl:if>

		<xsl:text>"techniques": [</xsl:text>
		<xsl:apply-templates select="$understanding.doc//*[@id = current()/@id]//*[@role='sufficient' or @role='advisory' or @role='tech-optional' or @role='failures'][olist or ulist or div5]"></xsl:apply-templates>
		<xsl:text>]</xsl:text>
		
		<xsl:text>}&#10;</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template name="sc-level">
		<xsl:param name="sc" select="."/>
		<xsl:choose>
			<xsl:when test="$sc/parent::*/@role = 'req'">A</xsl:when>
			<xsl:when test="$sc/parent::*/@role = 'bp'">AA</xsl:when>
			<xsl:when test="$sc/parent::*/@role = 'additional'">AAA</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="ulist" mode="sc-details">
		<xsl:text>{</xsl:text>
		<xsl:text>"type": "ulist",</xsl:text>
		<xsl:text>"items": [</xsl:text>
		<xsl:apply-templates select="item" mode="sc-details"/>
		<xsl:text>]</xsl:text>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="item" mode="sc-details">
		<xsl:variable name="text"><xsl:apply-templates select="p" mode="sc-text"/></xsl:variable>
		<xsl:text>{</xsl:text>
		<xsl:text>"handle": "</xsl:text><xsl:value-of select="wcag:json-string(p/emph[@role = 'sc-handle'])"/><xsl:text>",</xsl:text><!-- requested key was title -->
		<xsl:text>"text": "</xsl:text><xsl:value-of select="wcag:json-string($text)"/><xsl:text>"</xsl:text>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="p" mode="sc-details">
		<xsl:text>{</xsl:text>
		<xsl:text>"type": "p",</xsl:text>
		<xsl:text>"text": "</xsl:text><xsl:value-of select="wcag:json-string(.)"/><xsl:text>"</xsl:text>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="note" mode="sc-details">
		<xsl:text>{</xsl:text>
		<xsl:text>"type": "note",</xsl:text>
		<xsl:text>"text": "</xsl:text><xsl:value-of select="wcag:json-string(.)"/><xsl:text>"</xsl:text>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="p[@role = 'i' or @role = 'v']" mode="sc-text">
		<xsl:apply-templates mode="sc-text"/>
	</xsl:template>
	
	<xsl:template match="emph[@role = 'sc-handle']" mode="sc-text"/>
	
	<xsl:template match="div2[@role = 'gladvisory'] | div4[@role = 'sufficient'] | div4[@role = 'advisory'] | div4[@role = 'failures'] | div4[@role = 'tech-optional'][olist or ulist or div5]">
		<xsl:text>{</xsl:text>
		<xsl:text>"</xsl:text>
		<xsl:choose>
			<xsl:when test="@role = 'sufficient'">sufficient</xsl:when>
			<xsl:when test="@role = 'failures'">failure</xsl:when>
			<xsl:otherwise>advisory</xsl:otherwise>
		</xsl:choose>
		<xsl:text>": [</xsl:text>
		<xsl:apply-templates select="ulist/item | olist/item" mode="technique"/>
		<xsl:if test="div5[@role = 'situation']">
			<xsl:text>{</xsl:text>
			<xsl:text>"situations": [</xsl:text>
			<xsl:apply-templates select="div5[@role = 'situation']" mode="situation"/>
			<xsl:text>]</xsl:text>
			<xsl:text>}</xsl:text>
		</xsl:if>
		<xsl:text>]</xsl:text>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="div5[@role = 'situation']" mode="situation">
		<xsl:text>{</xsl:text>
		<xsl:text>"title": "</xsl:text><xsl:value-of select="wcag:json-string(head)"/><xsl:text>",</xsl:text>
		<xsl:text>"techniques": [</xsl:text>
		<xsl:apply-templates select="ulist/item | olist/item" mode="technique"/>
		<xsl:text>]</xsl:text>
		<!-- sections, comma before last brace -->
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="div2/ulist | div4/ulist | div5/ulist"></xsl:template>
	
	<xsl:template match="item[p/loc][count(p/loc) = 1]" mode="technique">
		<xsl:apply-templates select="p/loc" mode="technique">
			<xsl:with-param name="using" select="ulist | olist"/>
		</xsl:apply-templates>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="item[p/loc][count(p/loc) > 1]" mode="technique">
		<xsl:text>{</xsl:text>
		<xsl:text>"and": </xsl:text>
		<xsl:text>[</xsl:text>
		<xsl:apply-templates select="p/loc" mode="technique"/>
		<xsl:text>]</xsl:text>
		<xsl:if test="ulist | olist">
			<xsl:call-template name="using">
				<xsl:with-param name="list" select="ulist | olist"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="item[not(p/loc)]" mode="technique">
		<xsl:text>{</xsl:text>
		<xsl:text>"id": "TECH:future</xsl:text><xsl:number/><xsl:text>",</xsl:text>
		<xsl:text>"title": "</xsl:text><xsl:value-of select="wcag:json-string(.)"/><xsl:text>"</xsl:text><!-- requested key was text -->
		<xsl:if test="ulist | olist">
			<xsl:call-template name="using">
				<xsl:with-param name="list" select="ulist | olist"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>
	
	<xsl:template match="loc" mode="technique">
		<xsl:param name="using"/>
		<xsl:text>{</xsl:text>
		<xsl:text>"id": "TECH:</xsl:text>
		<xsl:value-of select="@href"/>
		<xsl:text>"</xsl:text>
		<xsl:if test="$using">
			<xsl:call-template name="using">
				<xsl:with-param name="list" select="$using"/>
			</xsl:call-template>
		</xsl:if>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:template>

	<xsl:template name="using">
		<xsl:param name="list" select="."/>
		<xsl:text>,"using": [</xsl:text>
		<xsl:apply-templates select="$list/item" mode="technique"/>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<!-- Override imported templates that are causing problems -->
	<xsl:template match="head">
		<xsl:apply-templates/>
	</xsl:template>
</xsl:stylesheet>