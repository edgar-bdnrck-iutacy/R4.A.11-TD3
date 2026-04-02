import 'package:flutter/foundation.dart';

// Type utilitaire représentant soit un succès, soit un échec.
// Il évite de propager des exceptions jusque dans les widgets.
abstract class Result<V extends Object, F extends Object> {
  factory Result.success(V value) => SuccessResult(value);

  factory Result.failure(F failure) => FailureResult(failure);

  bool get isSuccess;
  bool get isFailure;

  V? get value;
  F? get failure;
}

@immutable
// Cas où l'opération réussit et renvoie une valeur.
class SuccessResult<V extends Object, F extends Object>
    implements Result<V, F> {
  const SuccessResult(this._value);

  final V _value;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  V get value => _value;

  @override
  F? get failure => null;
}

@immutable
// Cas où l'opération échoue et renvoie une erreur.
class FailureResult<V extends Object, F extends Object>
    implements Result<V, F> {
  const FailureResult(this._failure);

  final F _failure;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  V? get value => null;

  @override
  F get failure => _failure;
}

// Type vide utilisé quand une opération réussit sans donnée métier à retourner.
class Unit {
  const Unit._();
}

const unit = Unit._();
