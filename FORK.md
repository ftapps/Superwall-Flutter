# Fork FT Apps — por que ele existe

Fork de [`superwall/Superwall-Flutter`](https://github.com/superwall/Superwall-Flutter)
mantido para o app **Vade Mecum**.

O plugin oficial no pub.dev fixa versões do SDK nativo que ficam meses atrás das
releases nativas de iOS e Android. Este fork existe só para adiantar esse pino —
e, num segundo momento, para adicionar suporte a Swift Package Manager.

Base: tag `2.4.12` (commit `e21ef56`).

## O que mudou em relação ao upstream

| Arquivo | Upstream 2.4.12 | Aqui |
|---|---|---|
| `ios/superwallkit_flutter.podspec` | `SuperwallKit 4.14.2` | `SuperwallKit 4.16.1` |
| `android/build.gradle` | `superwall-android:2.7.11` | `superwall-android:2.7.24` |

Nenhuma linha de código Swift, Kotlin ou Dart foi tocada. São dois pinos de versão.

## Por que 2.7.24 e não 2.8.x no Android

O Superwall-Android **2.8.0 quebra o bridge deste plugin**:

- `PurchaseController.purchase(activity, productDetails: ProductDetails, basePlanId, offerId)`
  foi removido em favor de `purchase(activity, product: StoreProduct, basePlanId, offerId)`.
  O bridge implementa a assinatura antiga em
  `android/src/main/kotlin/com/superwall/superwallkit_flutter/PurchaseControllerHost.kt:24`.
- A Google Play Billing Library saltou de 8.0.0 para 9.1.0, enquanto o
  `android/build.gradle` deste plugin ainda declara `billing:8.0.0`.
- O `minSdk` do SDK subiu de 21 para 23 (irrelevante para o Vade Mecum, que está em 26).

A linha 2.7.x segue recebendo backports — o 2.7.24 saiu em 11/08/2026, no mesmo dia
do 2.8.1. Enquanto o upstream não adaptar o bridge para a nova assinatura, **2.7.24
é o teto seguro**.

No iOS não há quebra alguma entre 4.14.2 e 4.16.1. A única mudança de API é a
deprecação de `SuperwallOptions.isExternalDataCollectionEnabled` (usada em
`ios/Classes/Mappers/OptionsMapper.swift:76`), que gera aviso de compilação e
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

Para builds de release, troque `ref` pelo SHA do commit — assim o build fica
reprodutível e não segue a ponta do branch sem querer.

## Como rebasear numa versão nova do upstream

```sh
git remote add upstream https://github.com/superwall/Superwall-Flutter.git   # uma vez só
git fetch upstream --tags
git rebase <nova-tag>          # ex.: 2.4.13
```

Os commits deste fork tocam duas linhas e um arquivo novo (este aqui), então o
rebase tende a ser limpo. Se a nova tag já pinar versões nativas iguais ou mais
novas do que as daqui, **descarte o commit de bump** — ele deixou de ser necessário.

Antes de subir os pinos de novo, confira as release notes dos dois SDKs nativos
procurando mudanças em `PurchaseController`, `PaywallPresentationHandler`,
`subscriptionStatus`, `Superwall.configure` e `ActivityProvider` — é onde o bridge
encosta. Quebra nesses pontos aparece em tempo de compilação, não em runtime.

## Quando abandonar este fork

Assim que o upstream publicar uma versão que já traga pinos nativos recentes **e**
suporte a Swift Package Manager, apague o `dependency_overrides` do app e volte
para o pub.dev. Este fork é ponte, não destino.
