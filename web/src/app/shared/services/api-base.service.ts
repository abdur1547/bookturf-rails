import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { inject } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { environment } from 'src/environments/environment';

export abstract class ApiBaseService<T> {
  protected readonly apiVersion: string = 'v0';
  protected readonly http: HttpClient = inject(HttpClient);
  protected readonly baseUrl: string = `${environment.apiBaseUrl}/${this.apiVersion}`;

  public list(url: string, params?: Record<string, string | number | boolean | undefined>): Observable<T[]> {
    return this.http
      .get<T[]>(`${this.baseUrl}/${url}`, { params: this.buildParams(params) })
      .pipe(catchError((error: HttpErrorResponse) => this.handleError('list', error)));
  }

  public get(url: string, params?: Record<string, string | number | boolean | undefined>): Observable<T> {
    return this.http
      .get<T>(`${this.baseUrl}/${url}`, { params: this.buildParams(params) })
      .pipe(catchError((error: HttpErrorResponse) => this.handleError('get', error)));
  }

  public create(url: string, payload: Partial<T>): Observable<T> {
    return this.http
      .post<T>(`${this.baseUrl}/${url}`, payload)
      .pipe(catchError((error: HttpErrorResponse) => this.handleError('create', error)));
  }

  public update(url: string, id: string | number, payload: Partial<T>): Observable<T> {
    return this.http
      .put<T>(`${this.baseUrl}/${url}/${id}`, payload)
      .pipe(catchError((error: HttpErrorResponse) => this.handleError('update', error)));
  }

  public delete(url: string, id: string | number): Observable<void> {
    return this.http
      .delete<void>(`${this.baseUrl}/${url}/${id}`)
      .pipe(catchError((error: HttpErrorResponse) => this.handleError('delete', error)));
  }

  protected handleError(operation: string, error: HttpErrorResponse): Observable<never> {
    const message = this.formatErrorMessage(operation, error);
    console.error(`[ApiBaseService] ${message}`, {
      status: error.status,
      url: error.url,
      body: error.error,
    });
    return throwError(() => new Error(message));
  }

  private formatErrorMessage(operation: string, error: HttpErrorResponse): string {
    const serverMessage = error.error?.message || error.message || 'Unknown error from server';
    return `API ${operation} failed: ${serverMessage}`;
  }

  private buildParams(params?: Record<string, string | number | boolean | undefined>): HttpParams {
    let httpParams = new HttpParams();

    if (!params) {
      return httpParams;
    }

    Object.entries(params).forEach(([key, value]) => {
      if (value === undefined || value === null) {
        return;
      }

      httpParams = httpParams.set(key, String(value));
    });

    return httpParams;
  }
}
