import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base use case class for all use cases in the application
/// Implements clean architecture principles
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require parameters
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Use case that returns a stream
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// Use case that returns a stream without parameters
abstract class StreamUseCaseNoParams<Type> {
  Stream<Either<Failure, Type>> call();
}

/// No parameters class for use cases that don't require parameters
class NoParams {
  const NoParams();
}

/// Common repository interface for all repositories
abstract class Repository {}

/// Base data source interface
abstract class DataSource {}

/// Remote data source interface
abstract class RemoteDataSource extends DataSource {}

/// Local data source interface  
abstract class LocalDataSource extends DataSource {}