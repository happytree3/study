
문제 1.

#include <stdio.h>
// C 언어의 표준 입력 출력 라이브러리를 포함시키는 코드
// printf , scanf 사용할 수 있게 해준다. 

int main() {	// 반드시 처음에 사용되야 함.
    int arr[] = {1, 2, 3, 4, 5}; // C언어에서 배열 선언 방법. 자바랑 같다.
    int sum = 0;	
    int i;
    for (i = 0; i < (빈칸); i++) {
        sum += arr[i];
    }
    printf("Sum: %d\n", sum);	// %d 는 정수형 변수. %d\n은 출력되지 않고 Sum : 15 이렇게 나오고 줄이 바뀐다.
    return 0; 	// return 0은 main 함수의 종료를 의미한다. 0은 정상적인 종료.
}

=> 정답 : arr.length 또는 5
=> 실제 정답 : sizeof(arr) / sizeof(arr[0]) 또는 5


문제 2.

#include <stdio.h>
#include <string.h>

void reverse_string(char str[]) {
    int length = strlen(str);
    for (int i = 0; i < length / 2; i++) {
        char temp = str[i];
		str[i] = str[length - i - 1];
        str[length - i -1] = temp;
    }
}

int main() {
    char str[] = "Hello";
    reverse_string(str);
    printf("Reversed string: %s\n", str);
    return 0;
}

=> length는 5가 나오고
length /2 는 2가 나오니까 0 1 총 2번 진행. %는 나머지 / 는 몫.
처음에 temp 는 H

str[0] = str[4]
str[4] = H

=> oellH

str[1] => temp라서 temp는 e

str[1] = str[3]
str[3] = temp = e

정답 : olleH 

//여기서 중요 관점 포인트 ! temp에 담는 이유를 잘 생각하기.
// str[i]의 값이 변할꺼기 때문에 temp로 따로 빼두는 것.


문제 3.

#include ＜stdio.h＞
int func(int a) {
  if (a ＜= 1) return 1;
  return a * func(a - 1);
}
 
int main() {
  int a;
  scanf("%d", &a);
  printf("%d", func(a));
}
=> 4를 넣으면 4*3*2*1 이 될듯?




문제 4.

#include ＜stdio.h＞
int main() {
  int number = 1234;
  int div = 10;
  int result = 0;
 
  while (number ( 1 ) 0) {
    result = result * div;
    result = result + number ( 2 ) div;
    number = number ( 3 ) div;
  }
 
  printf("%d", result);
  return 0;
}


문제 5.

#include ＜stdio.h＞
int isPrime(int number) { 
  int i; 
  for (i=2; i＜number; i++) { 
    if (number % i == 0) return 0; 
  } 
  return 1; 
} 
 
int main(void) { 
  int number = 13195, max_div=0, i; 
  for (i=2; i＜number; i++) 
  if (isPrime(i) == 1 && number % i == 0) max_div = i; 
  printf("%d", max_div); 
  return 0; 
}