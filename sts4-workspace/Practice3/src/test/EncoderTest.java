package test;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.net.URLEncoder;

public class EncoderTest {

	public static void main(String[] args) throws UnsupportedEncodingException {
		
		String encoText = "colrCd:(05 OR 17)";

		String encodedParam = URLEncoder.encode(encoText, "UTF-8");
		            
		// 서버에서 API 호출을 위해 URL을 구성
		// String apiUrl = "http://example.com/api?filter=" + encodedParam;

		System.out.println("encoText ==> " + encoText);
		System.out.println("encoding ==> " + encodedParam + "\n");
		
		String decoText = "colrCd%3A%2805%20OR%2017%29";
		
		String decodedParam = URLDecoder.decode(decoText, "UTF-8");
	
		System.out.println("decoText ==> " + decoText);
		System.out.println("decoding ==> " + decodedParam);
	}

}
