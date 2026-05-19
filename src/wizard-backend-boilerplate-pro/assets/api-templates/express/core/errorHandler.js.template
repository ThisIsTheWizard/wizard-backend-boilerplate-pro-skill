export function errorHandler(err, _req, res, _next) {
  const statusCode = err.statusCode ?? 500;
  const code = err.code ?? (statusCode === 500 ? 'INTERNAL_ERROR' : 'ERROR');

  if (statusCode >= 500) {
    console.error('[ErrorHandler]', err);
  }

  res.status(statusCode).json({
    error: err.message ?? 'Internal server error',
    code,
    ...(err.details ? { details: err.details } : {}),
  });
}

export function createError(message, statusCode = 500, code, details) {
  const err = new Error(message);
  err.statusCode = statusCode;
  err.code = code;
  err.details = details;
  return err;
}
