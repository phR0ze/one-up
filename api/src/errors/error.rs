#[derive(Debug)]
pub struct Error {
  pub msg: String,
  pub kind: ErrorKind,
  pub source: Option<ErrorSource>,
}

impl Error {

  /// Simple constructor
  pub fn http(status: axum::http::StatusCode, msg: &str) -> Self {
    Self {
      msg: msg.into(),
      kind: ErrorKind::Other,
      source : Some(ErrorSource::Http(super::HttpError {
        msg: msg.into(),
        status,
      })),
    }
  }

  /// Create a new error from a SQLx error
  /// - `e`: The SQLx error
  /// - `msg`: The error context message
  pub fn from_sqlx(e: sqlx::Error, msg: &str) -> Self {
    Self {
      msg: msg.into(),
      kind: if Self::is_sqlx_unique_violation(&e) {
        ErrorKind::NotUnique
      } else if Self::is_sqlx_not_found(&e) {
        ErrorKind::NotFound
      } else {
        ErrorKind::Other
      },
      source : Some(ErrorSource::Sqlx(e)),
    }
  }

  /// Determine if the given sqlx error is a unique violation error
  /// - `e`: The SQLx error
  pub fn is_sqlx_unique_violation(e: &sqlx::Error) -> bool {
    if let sqlx::Error::Database(db_err) = &e {
      if db_err.kind() == sqlx::error::ErrorKind::UniqueViolation {
        return true;
      }
    }
    false
  }

  /// Determine if the given sqlx error is a not found error
  /// - `e`: The SQLx error
  pub fn is_sqlx_not_found(e: &sqlx::Error) -> bool {
    if let sqlx::Error::RowNotFound = &e {
      return true;
    }
    false
  }

  /// Expose the source variant directly
  pub fn as_http(&self) -> Option<&super::HttpError> {
    if let Some(ErrorSource::Http(e)) = &self.source {
      return Some(e);
    }
    None
  }

  /// Convert the error into an HttpError equivalent
  pub fn to_http(self) -> super::HttpError {
    super::HttpError {
      msg: self.msg,
      status: match self.source {
        Some(ErrorSource::Http(e)) => e.status,
        Some(ErrorSource::Sqlx(_)) => {
          match self.kind {
            ErrorKind::NotFound => axum::http::StatusCode::NOT_FOUND,
            ErrorKind::NotUnique => axum::http::StatusCode::CONFLICT,
            _ => axum::http::StatusCode::BAD_REQUEST,
          } 
        },
        Some(ErrorSource::JsonRejection(e)) => e.status(),
        None => axum::http::StatusCode::INTERNAL_SERVER_ERROR,
      },
    }
  }
}

impl std::fmt::Display for Error {
  fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
    match &self.source {
        Some(ErrorSource::Sqlx(e)) => write!(f, "{}: {}", self.msg, e)?,
        Some(ErrorSource::JsonRejection(e)) => write!(f, "{}: {}", self.msg, e)?,
        Some(ErrorSource::Http(e)) => write!(f, "{}", e)?,
        None => write!(f, "{}", self.msg)?,
    };
    Ok(())
  }
}

impl std::error::Error for Error {
  fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
    match &self.source {
        Some(ErrorSource::Sqlx(e)) => Some(e),
        Some(ErrorSource::JsonRejection(e)) => Some(e),
        Some(ErrorSource::Http(e)) => None,
        None => None,
    }
  }
}

// Provides the ability to use `Error` as a response
impl axum::response::IntoResponse for Error {
  fn into_response(self) -> axum::response::Response {
    self.to_http().into_response()
  }
}

// Custom regjection implementation to convert `From<JsonRejection>` to `Error`
impl From<axum::extract::rejection::JsonRejection> for Error {
  fn from(rejection: axum::extract::rejection::JsonRejection) -> Self {
    Self {
      msg: rejection.body_text(),
      kind: ErrorKind::Rejection,
      source : Some(ErrorSource::JsonRejection(rejection)),
    }
  }
}

/// An extensible way to capture various error message types
#[derive(Debug, PartialEq, Eq)]
pub enum ErrorKind {
  NotFound,
  NotUnique,
  Rejection,
  Other,
}

/// The kind of parse errors that can be generated
#[derive(Debug)]
pub enum ErrorSource {
  Sqlx(sqlx::Error),
  Http(super::HttpError),
  JsonRejection(axum::extract::rejection::JsonRejection),
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::state;

  #[tokio::test]
  async fn test_database_conflict() {
    let state = state::test().await;
    let name = "test_user";

    // Generate a conflict error
    sqlx::query(r#"INSERT INTO users (name) VALUES (?)"#)
    .bind(name).execute(state.db()).await.expect("can't insert user");
    let err = sqlx::query(r#"INSERT INTO users (name) VALUES (?)"#)
    .bind(name).execute(state.db()).await.unwrap_err();

    // Create the new error wrapping the SQLx error
    Error {
      kind: ErrorKind::NotUnique,
      msg: "Database conflict".to_string(),
      source : Some(ErrorSource::Sqlx(err)),
    };
  }
}
