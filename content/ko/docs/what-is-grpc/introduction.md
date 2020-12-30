---
title: gRPC 소개
short_title: 소개
description: gRPC와 프로토콜 버퍼 소개.
weight: 10
spelling: cSpell:ignore ponycopter
---

이 페이지에서는 gRPC와 프로토콜 버퍼를 소개합니다. gRPC는
프로토콜 버퍼를 인터페이스 정의 언어(**IDL**)와 기본 메시지
교환 형식으로 모두 사용할 수 있습니다. gRPC 그리고/또는
프로토콜 버퍼를 처음 사용하는 경우 이 글을 읽어보세요! gRPC를 실습으로
먼저 살펴보고 싶다면 [빠른 시작](/ko/docs/quickstart)을 해보세요.

## 개요

gRPC에서는 클라이언트 애플리케이션이 마치 로컬 오브젝트인 것처럼
다른 머신의 서버 어플리케이션에서 메서드를 직접 호출할 수 있어
분산된 애플리케이션과 서비스를 쉽게 만들 수 있습니다. 많은 RPC
시스템에서와 같이, gRPC는 그 매개변수와 반환 유형을 가지고 원격으로
호출할 수 있는 메서드를 명시하면서 서비스를 정의한다는 아이디어를 기반으로
합니다. 서버 측에서는 서버가 이 인터페이스를 구현하고 gRPC 서버를 실행하여
클라이언트 호출을 처리합니다. 클라이언트 측에서는 서버와 동일한 메서드를
제공하는 스텁(stub, 일부 언어에서는 클라이언트만 칭함)이 있습니다.

![Concept Diagram](/img/landing-2.svg)

gRPC 클라이언트와 서버는 구글 서버부터 사용자의 데스크톱에
이르기까지 다양한 환경에서 서로 실행하고 대화할 수 있으며, gRPC가
지원하는 모든 언어로 작성될 수 있습니다. 예를 들어 Go, Python 또는
Ruby 클라이언트와 함께 Java gRPC 서버를 쉽게 만들 수 있다. 또한
최신 구글 API는 인터페이스에 gRPC 버전이 포함되어 있어 구글이
제공하는 기능을 애플리케이션에 쉽게 구축할 수 있다.

### 프로토콜 버퍼 사용

기본적으로 gRPC는 (JSON과 같은 다른 데이터 형식과 함께 사용할 수 있지만)
구조화된 데이터를 직렬화하기 위해 구글의 성숙한 오픈소스 메커니즘인
[프로토콜 버퍼][]를 사용합니다. 여기에서는 프로토콜 버퍼가 어떻게 동작하는지
간단히 소개합니다. 프로토콜 버퍼를 이미 잘 알고 있다면 다음 섹션으로
넘어가세요.

프로토콜 버퍼를 사용할 때 첫 번째 단계는 *proto 파일*에서
직렬화할 데이터의 구조를 정의하는 것입니다. 여기서 proto 파일이란
`.proto` 확장자를 갖는 일반 텍스트 파일입니다. 프로토콜 버퍼
데이터는 *message*로 구조화되며, 여기서 각 메시지는 *field*라고
불리는 일련의 이름-값 쌍을 포함하는 정보의 작은 논리 레코드입니다.
여기 간단한 예가 있습니다.

```proto
message Person {
  string name = 1;
  int32 id = 2;
  bool has_ponycopter = 3;
}
```

데이터 구조를 명시한 후에는 proto 정의에서 원하는 언어로 데이터 접근
클래스를 생성하기 위해 프로토콜 버퍼 컴파일러 `protoc`를 사용합니다.
이들은 `name()`, `set_name()`과 같은 각 필드에 대한 간단한 접근자뿐만
아니라 전체 구조를 원시 바이트로 직렬화하고 반대로 원시 바이트에서
파싱하는 방법도 제공합니다. 예를 들어 선택한 언어가 C++인 경우 위의
예에서 컴파일러를 실행하면 `Person`이라는 클래스가 생성됩니다. 그 후
애플리케이션에서 이 클래스를 사용하여 `Person` 프로토콜 버퍼 메시지를
생성, 직렬화 및 검색할 수 있습니다.

프로토콜 버퍼 메시지로 명시된 RPC 메서드 매개 변수
및 반환 타입을 사용하여 일반 proto 파일에서 gRPC 서비스를
정의합니다.

```proto
// 인사 서비스 정의
service Greeter {
  // 인사말 보내기
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// 사용자명을 포함한 요청 메시지
message HelloRequest {
  string name = 1;
}

// 인사말을 포함한 응답 메시지
message HelloReply {
  string message = 1;
}
```

gRPC는 특별한 gRPC 플러그인과 함께 `protoc`를 사용하여
proto 파일에서 코드를 생성합니다. gRPC 클라이언트
및 서버 코드뿐만 아니라 메시지 타입을 생성, 직렬화 및
검색하기 위한 일반 프로토콜 버퍼 코드도 생성됩니다.
아래에서 해당 예시를 볼 수 있습니다.

여러분이 선택한 언어의 gRPC 플러그인과 `protoc`를 설치하는 방법을 포함하여 프로토콜
버퍼에 대한 자세한 내용은 [프로토콜 버퍼 문서][프로토콜 버퍼]를 참조하세요.

## 프로토콜 버퍼 버전

[프로토콜 버퍼][]는 오픈 소스 사용자가 한동안 이용할 수 있었지만,
이 사이트의 대부분의 예에서는 프로토콜 버퍼 버전 3 (proto3)를
사용하고 있습니다. 버전 3는 구문이 약간 간소화되고, 몇 가지 유용한
새로운 기능이 있으며, 더 많은 언어를 지원합니다. proto3는 현재
[프로토콜 버퍼 GitHub 저장소][]에서 Java, C++, Dart, Python, Objective-C,
C#, lite-runtime (안드로이드 자바), Ruby, JavaScript 뿐만
아니라 [golang/protobuf GitHub 저장소][]의 Go 언어 생성기 등을 개발할 때
사용할 수 있습니다. [proto3 언어 가이드][]와 각 언어의 [레퍼런스 문서][]에서
자세한 내용을 확인할 수 있습니다. 레퍼런스 문서에는 `.proto` 파일 형식에 대한
[공식 규격][]도 포함되어 있습니다.

일반적으로 proto2 (현재 기본 프로토콜 버퍼 버전)를 사용할 수 있지만,
gRPC와 함께 proto3를 사용하는 것을 권장합니다. proto3를 사용하면 gRPC를
지원하는 모든 언어를 사용할 수 있고, proto2 클라이언트가 proto3 서버와
통신하거나 그 반대의 경우에도 호환성 이슈를 피할 수 있습니다.

[공식 규격]: https://developers.google.com/protocol-buffers/docs/reference/proto3-spec
[golang/protobuf GitHub 저장소]: https://github.com/golang/protobuf
[proto3 언어 가이드]: https://developers.google.com/protocol-buffers/docs/proto3
[프로토콜 버퍼 GitHub 저장소]: https://github.com/google/protobuf/releases
[프로토콜 버퍼]: https://developers.google.com/protocol-buffers/docs/overview
[레퍼런스 문서]: https://developers.google.com/protocol-buffers/docs/reference/overview
