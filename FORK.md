# Fork FT Apps — por que ele existe

Fork de [`superwall/Superwall-Flutter`](https://github.com/superwall/Superwall-Flutter)
mantido para o app **Vade Mecum**.

O plugin oficial no pub.dev fixa versões do SDK nativo que ficam meses atrás das
releases nativas de iOS e Android, e não suporta Swift Package Manager — algo que
o Flutter avisa a cada build e promete transformar em erro.

Base: tag `2.4.12` (commit `e21ef56`).

## O que mudou em relação ao upstream

**1. Pinos do SDK nativo**

| Arquivo | Upstream 2.4.12 | Aqui |
|---|---|---|
| `ios/superwallkit_flutter.podspec` | `SuperwallKit 4.14.2` | `SuperwallKit 4.16.3` |
| `android/build.gradle` | `superwall-android:2.7.11` | `superwall-android:2.7.24` |

**2. Suporte a Swift Package Manager**

Os fontes saíram de `ios/Classes/` para
`ios/superwallkit_flutter/Sources/superwallkit_flutter/`, com um `Package.swift`
ao lado. O CocoaPods continua funcionando em paralelo — o `source_files` do
podspec aponta para o novo caminho.

Nenhuma linha de código Swift, Kotlin ou Dart foi alterada: os arquivos só
mudaram de lugar (o git registra como rename puro).

⚠️ **O pino do SuperwallKit agora aparece em dois lugares** — `Package.swift` e
`superwallkit_flutter.podspec`. Suba os dois juntos, sempre.

## Por que 2.7.24 e não 2.8.x no Android

**O motivo é a Google Play Billing, não o bridge.**

Uma versão anterior deste arquivo dizia que o 2.8.0 quebrava o bridge, porque o
`PurchaseController.purchase(activity, productDetails, ...)` teria sido removido.
Isso estava errado — foi leitura das release notes, não do código. Na interface
real da 2.8.1 o método antigo continua lá, apenas `@Deprecated` e com
implementação padrão, e o novo overload que recebe `StoreProduct` tem um default
que roteia produtos do Google Play para o antigo, com este comentário no próprio
SDK: *"so existing implementations keep working"*.

Verificado empiricamente em 20/08/2026: apontando o plugin para a 2.8.1 e rodando
`:superwallkit_flutter:compileDebugKotlin --rerun-tasks`, o resultado é
`BUILD SUCCESSFUL`. Sai apenas um aviso em `PurchaseControllerHost.kt:24`
("overrides a deprecated member"), sem erro.

O impedimento real é de dependência:

| | Play Billing exigida |
|---|---|
| `superwall-android:2.8.1` | **9.1.0** |
| `superwall-android:2.7.24` | 8.0.0 |
| `revenuecat:purchases:10.17.0` (última em 20/08/2026) | **8.3.0** |

Só pode existir uma Play Billing no app, e os dois SDKs pedem majors diferentes.
Forçar 9.1.0 faz o RevenueCat, compilado contra a 8.3.0, rodar sobre uma versão
que removeu APIs; forçar 8.3.0 faz o mesmo com o Superwall na direção oposta.
Qualquer das duas é aposta no caminho de pagamento.

O `minSdk` do SDK subiu de 21 para 23 no 2.8.0 — irrelevante para o Vade Mecum,
que está em 26.

A linha 2.7.x recebeu backports até o 2.7.24, de 11/08/2026 — mesmo dia do 2.8.1.
Em 20/08/2026 o 2.7.24 seguia sendo o topo da linha 2.7.

**O gatilho para reavaliar não é o Superwall: é o RevenueCat publicar suporte à
Play Billing 9.** Quando publicar, a migração é pequena — subir o pino daqui,
subir o `purchases_flutter` e trocar o `force` da Billing no app. Sem bridge novo.
Não há pressa: o prazo do Google é Billing 8+ desde 31/08/2026, e o app está em
8.3.0.

No iOS não há quebra alguma entre 4.14.2 e 4.16.3. A única mudança de API é a
deprecação de `SuperwallOptions.isExternalDataCollectionEnabled` (usada em
`ios/superwallkit_flutter/Sources/superwallkit_flutter/Mappers/OptionsMapper.swift:76`), que gera aviso de compilação e
continua funcionando — o 4.16.0 mapeia o valor antigo para o novo
`EventTrackingBehavior`.

## Como o app consome

Em `vade_mecum/pubspec.yaml`:

```yaml
dependency_overrides:
  superwallkit_flutter:
    git:
      url: https://github.com/ftapps/Superwall-Flutter.git
      ref: ftapps/vade-mecum
```

O `ref` é um branch, mas o build segue reprodutível: o `pubspec.lock` do app
grava o `resolved-ref` (o SHA exato). Mudar de commit exige um
`flutter pub upgrade superwallkit_flutter` explícito.

Desde 12/08/2026 o app consome este plugin pelo **Swift Package Manager** — o
`enable-swift-package-manager` está ligado e o CocoaPods foi removido do iOS e
do macOS. Ou seja, na prática quem vale é o `Package.swift`; o podspec fica
para quem ainda usar pods.

Para exercitar o caminho SPM sem mexer no app, use um app descartável:

```sh
flutter create --platforms=ios spm_probe && cd spm_probe
# no pubspec: dependência path para este fork + flutter.config.enable-swift-package-manager: true
# no Runner.xcodeproj: IPHONEOS_DEPLOYMENT_TARGET >= 14.0
flutter build ios --debug --no-codesign
```

## Como rebasear numa versão nova do upstream

```sh
git remote add upstream https://github.com/superwall/Superwall-Flutter.git   # uma vez só
git fetch upstream --tags
git rebase <nova-tag>          # ex.: 2.4.13
```

Os commits deste fork tocam duas linhas e um arquivo novo (este aqui), então o
rebase tende a ser limpo. Se a nova tag já pinar versões nativas iguais ou mais
novas do que as daqui, **descarte o commit de bump** — ele deixou de ser necessário.

Antes de subir os pinos de novo, olhe `PurchaseController`,
`PaywallPresentationHandler`, `subscriptionStatus`, `Superwall.configure` e
`ActivityProvider` — é onde o bridge encosta.

**Não confie nas release notes para isso.** As do 2.8.0 anunciavam a remoção de
um método que na verdade só foi deprecado, e essa leitura errada travou o fork
numa versão por mais de uma semana sem necessidade. Leia a interface no
repositório do SDK, e confirme compilando: um `:superwallkit_flutter:compileDebugKotlin
--rerun-tasks` com o pino novo responde em segundos. Quebra nesses pontos aparece
em tempo de compilação, não em runtime — então o compilador é a fonte barata e
definitiva.

Confira também a Play Billing que o novo pino exige, no POM do Maven Central, e
compare com a que o RevenueCat declara. É aí que mora o impedimento real.

## Quando abandonar este fork

Assim que o upstream publicar uma versão que já traga pinos nativos recentes **e**
suporte a Swift Package Manager, apague o `dependency_overrides` do app e volte
para o pub.dev. Este fork é ponte, não destino.
