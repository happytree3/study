package test;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

import javax.swing.*;
import java.awt.*;
import java.io.IOException;
import java.net.URL;

public class kakaoImageChecker {

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            // GUI 실행
            try {
                String url = "https://pf.kakao.com/_aKxdLs/posts"; // 대상 URL
                String imageUrl = fetchImageUrl(url);
                if (imageUrl != null) {
                    showImageInPopup(imageUrl);
                } else {
                    JOptionPane.showMessageDialog(null, "이미지를 찾을 수 없습니다.");
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    // 웹 페이지에서 이미지 URL 가져오기
    private static String fetchImageUrl(String url) throws IOException {
        Document doc = Jsoup.connect(url).get();
        Element imgElement = doc.selectFirst(".wrap_fit_thumb");
        if (imgElement != null) {
            String style = imgElement.attr("style");
            return style.substring(style.indexOf("url(") + 4, style.indexOf(")")).replace("\"", "");
        }
        return null;
    }

    // 이미지를 팝업창에 표시하기
    private static void showImageInPopup(String imageUrl) {
        JFrame frame = new JFrame("게시물 이미지");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setSize(400, 300);
        
        // 이미지 라벨 생성
        ImageIcon imageIcon = new ImageIcon(imageUrl);
        JLabel imageLabel = new JLabel(imageIcon);
        
        frame.getContentPane().add(imageLabel, BorderLayout.CENTER);
        frame.setVisible(true);
    }
}