import java.util.*;

public class LOL {
    // 챔피언 목록 (한국어)
    private static final List<String> champions = Arrays.asList(
        "아트록스", "아리", "아칼리", "알리스타", "아무무",
        "애니비아", "애니", "애쉬", "아우렐리온 솔", "아지르",
        "바드", "블리츠크랭크", "브랜드", "브라움", "케이틀린",
        "카밀", "카시오페아", "초가스", "코르키", "다리우스",
        "다이아나", "문도", "드레이븐", "에코", "엘리스",
        "이블린", "이즈리얼", "피들스틱", "피오라", "피즈",
        "갈리오", "갱플랭크", "가렌", "나르", "그라가스",
        "그레이브즈", "그웬", "헤카림", "하이머딩거", "일라오이",
        "이렐리아", "아이번", "잔나", "자르반 4세", "잭스",
        "제이스", "진", "징크스", "카이사", "카르마",
        "카직스", "카사딘", "카타리나", "케일", "케인",
        "케넨", "카서스", "킨드레드", "클레드", "코그모",
        "르블랑", "리신", "레오나", "릴리아", "리산드라",
        "루시안", "룰루", "럭스", "말파이트", "말자하",
        "마오카이", "마스터이", "미스 포츈", "모르가나", "나미",
        "나서스", "노틸러스", "니코", "니달리", "녹턴",
        "누누", "올라프", "오리아나", "오른", "판테온",
        "뽀삐", "키야나", "라칸", "람머스", "렉사이",
        "렐", "레넥톤", "렝가", "리븐", "럼블",
        "라이즈", "사미라", "세주아니", "세나", "세라핀",
        "세트", "샤코", "쉔", "쉬바나", "신지드",
        "사이온", "시비르", "소나", "소라카", "스웨인",
        "신드라", "탐켄치", "탈리야", "탈론",
        "타릭", "티모", "쓰레쉬", "트리스타나", "트런들",
        "트린다미어", "트위스티드 페이트", "트위치", "우디르", "우르곳",
        "바루스", "베인", "베가", "벨코즈", "벡스",
        "비에고", "빅토르", "블라디미르", "볼리베어", "워윅",
        "오공", "자야", "제라스", "신자오", "야스오",
        "요네", "자크", "제드", "제리", "직스",
        "질리언", "자이라", "나피리", "닐라", "레나타", "모데카이저", "밀리오",
        "베이가", "벨베스", "브라이어", "사일러스", "스몰더", "스카너", "신짜오",
        "아크샨", "아펠리오스", "오로라", "요릭", "유미", "조이", "칼리스타", "퀸",
        "키아나", "파이크", "흐웨이"
    );

    private static Map<String, List<String>> assignedChampions = new HashMap<>();
    private static List<String> team1 = new ArrayList<>();
    private static List<String> team2 = new ArrayList<>();

    public static void main(String[] args) {
        assignChampions();
        System.out.println("팀 1: " + team1);
        System.out.println("팀 2: " + team2);
        System.out.println("\n초기 챔피언 배정:");
        assignedChampions.forEach((player, champs) -> 
            System.out.println(player + ": " + champs.get(champs.size() - 1))
        );

        System.out.println("\n리롤 진행:");
        rerollChampions(team1);
        rerollChampions(team2);

        System.out.println("\n최종 챔피언 배정:");
        assignedChampions.forEach((player, champs) -> 
            System.out.println(player + ": " + champs)
        );
    }

    private static void assignChampions() {
        for (int i = 0; i < 10; i++) {
            String player = "플레이어 " + (i + 1);
            assignedChampions.put(player, new ArrayList<>());
        }

        List<String> availableChampions = new ArrayList<>(champions);
        Collections.shuffle(availableChampions);

        for (int i = 0; i < 10; i++) {
            String player = "플레이어 " + (i + 1);
            String champion = availableChampions.get(i);
            assignedChampions.get(player).add(champion);
        }

        team1 = Arrays.asList("플레이어 1", "플레이어 2", "플레이어 3", "플레이어 4", "플레이어 5");
        team2 = Arrays.asList("플레이어 6", "플레이어 7", "플레이어 8", "플레이어 9", "플레이어 10");
    }

    private static void rerollChampions(List<String> teamPlayers) {
        Scanner scanner = new Scanner(System.in);
        for (String player : teamPlayers) {
            int rerollAttempts = 2;  // 각 플레이어당 리롤 기회
            while (rerollAttempts > 0) {  // 리롤 기회가 남아있는 동안 반복
                String currentChamp = assignedChampions.get(player).get(assignedChampions.get(player).size() - 1);
                System.out.print(player + "의 현재 챔피언: " + currentChamp + " 리롤 하시겠습니까? (y/n): ");
                String rerollChoice = scanner.nextLine();
                if (rerollChoice.equalsIgnoreCase("y")) {
                    // 새로운 챔피언 배정
                    String newChampion = champions.get(new Random().nextInt(champions.size()));
                    assignedChampions.get(player).add(newChampion);
                    System.out.println(player + "의 새로운 챔피언: " + newChampion);
                    rerollAttempts--;  // 리롤 기회 차감
                } else if (rerollChoice.equalsIgnoreCase("n")) {
                    break;  // 리롤 종료
                } else {
                    System.out.println("잘못된 값을 입력했습니다. 'y' 또는 'n'을 입력해 주세요.");
                    // 리롤 기회 차감하지 않음
                }
            }

            // 중복 제거한 챔피언 리스트 출력
            Set<String> uniqueChampions = new HashSet<>(assignedChampions.get(player));
            System.out.println(player + "의 챔피언 리스트: " + uniqueChampions);
        }

        // 팀 누적 챔피언 리스트 업데이트
        Set<String> teamUniqueChampions = new HashSet<>();
        for (String player : teamPlayers) {
            teamUniqueChampions.addAll(assignedChampions.get(player));
        }

        System.out.println(teamPlayers.get(0) + " ~ " + teamPlayers.get(4) + "의 누적 챔피언 리스트: " + teamUniqueChampions);
    }
}