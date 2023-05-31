/**
* @author Cloud Consulting Group
* @date 2022
*
* @group Mock
*
* @description VB Info Picture Mock for testing purposes
*/
@isTest
public class VBInfoPictureMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();

        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Location', 'Apex Test Picture Location');
        res.setStatusCode(302);

        String requestBody = '';
        requestBody += '<List>';
        requestBody += '    <item>';
        requestBody += '        <id>5a7883d6586ba91f9e01dba2</id>';
        requestBody += '        <kategorie>vbportraithomepage</kategorie>';
        requestBody += '        <aufloesung>121x121</aufloesung>';
        requestBody += '        <vbNummer>7078330</vbNummer>';
        requestBody += '        <url>https://www.dvag.de/content/dam/vbdata/dvag/g/e/r/gerhard.stangl/vbportrait_mask_01.png/_jcr_content/renditions/cq5dam.vbportraithomepage.121.121.png</url>';
        requestBody += '        <hash>94181fffd2866e8c3d3674ccb22ef17e</hash>';
        requestBody += '        <publicUrl>https://vbinfo.dvag/v1/vermoegensberater/94181fffd2866e8c3d3674ccb22ef17e/bilder/vbportraithomepage/121x121</publicUrl>';
        requestBody += '    </item>';
        requestBody += '    <item>';
        requestBody += '        <id>58ec9a8f586ba999000efa8f</id>';
        requestBody += '        <kategorie>vbportraithomepage</kategorie>';
        requestBody += '        <aufloesung>144x144</aufloesung>';
        requestBody += '        <vbNummer>7078330</vbNummer>';
        requestBody += '        <url>https://www.dvag.de/content/dam/vbdata/dvag/g/e/r/gerhard.stangl/vbportrait_mask_01.png/_jcr_content/renditions/cq5dam.vbportraithomepage.144.144.png</url>';
        requestBody += '        <hash>94181fffd2866e8c3d3674ccb22ef17e</hash>';
        requestBody += '        <publicUrl>https://vbinfo.dvag/v1/vermoegensberater/94181fffd2866e8c3d3674ccb22ef17e/bilder/vbportraithomepage/144x144</publicUrl>';
        requestBody += '    </item>';
        requestBody += '    <item>';
        requestBody += '        <id>5a7883d6586ba91f9e01dba1</id>';
        requestBody += '        <kategorie>vbportraithomepage</kategorie>';
        requestBody += '        <aufloesung>600x600</aufloesung>';
        requestBody += '        <vbNummer>7078330</vbNummer>';
        requestBody += '        <url>https://www.dvag.de/content/dam/vbdata/dvag/g/e/r/gerhard.stangl/vbportrait_mask_01.png/_jcr_content/renditions/cq5dam.vbportraithomepage.600.600.png</url>';
        requestBody += '        <hash>94181fffd2866e8c3d3674ccb22ef17e</hash>';
        requestBody += '        <publicUrl>https://vbinfo.dvag/v1/vermoegensberater/94181fffd2866e8c3d3674ccb22ef17e/bilder/vbportraithomepage/600x600</publicUrl>';
        requestBody += '    </item>';
        requestBody += '    <item>';
        requestBody += '        <id>5a7883d6586ba91f9e01dba0</id>';
        requestBody += '        <kategorie>vbportraithomepage</kategorie>';
        requestBody += '        <aufloesung>original</aufloesung>';
        requestBody += '        <vbNummer>7078330</vbNummer>';
        requestBody += '        <url>https://www.dvag.de/content/dam/vbdata/dvag/g/e/r/gerhard.stangl/vbportrait_mask_01.png/_jcr_content/renditions/cq5dam.vbportraithomepage.original</url>';
        requestBody += '        <hash>94181fffd2866e8c3d3674ccb22ef17e</hash>';
        requestBody += '        <publicUrl>https://vbinfo.dvag/v1/vermoegensberater/94181fffd2866e8c3d3674ccb22ef17e/bilder/vbportraithomepage/original</publicUrl>';
        requestBody += '    </item>';
        requestBody += '</List>';

        res.setBody(requestBody);
        
        return res;
    }
}