import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

export abstract class ApiBaseService<T> {
    protected constructor(protected readonly http: HttpClient, protected readonly baseUrl: string) { }

    public list(params?: Record<string, string | number | boolean | undefined>): Observable<T[]> {
        return this.http
            .get<T[]>(this.baseUrl, { params: this.buildParams(params) })
            .pipe(catchError((error: HttpErrorResponse) => this.handleError('list', error)));
    }

    public get(id: string | number, params?: Record<string, string | number | boolean | undefined>): Observable<T> {
        return this.http
            .get<T>(this.resourceUrl(id), { params: this.buildParams(params) })
            .pipe(catchError((error: HttpErrorResponse) => this.handleError('get', error)));
    }

    public create(payload: Partial<T>): Observable<T> {
        return this.http
            .post<T>(this.baseUrl, payload)
            .pipe(catchError((error: HttpErrorResponse) => this.handleError('create', error)));
    }

    public update(id: string | number, payload: Partial<T>): Observable<T> {
        return this.http
            .put<T>(this.resourceUrl(id), payload)
            .pipe(catchError((error: HttpErrorResponse) => this.handleError('update', error)));
    }

    public delete(id: string | number): Observable<void> {
        return this.http
            .delete<void>(this.resourceUrl(id))
            .pipe(catchError((error: HttpErrorResponse) => this.handleError('delete', error)));
    }

    protected resourceUrl(id: string | number): string {
        return `${this.baseUrl}/${id}`;
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
