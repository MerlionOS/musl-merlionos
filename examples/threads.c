/*
 * Pthreads + Mutex — demonstrates threading on MerlionOS.
 *
 * Compile:
 *   x86_64-linux-musl-gcc -static -pthread -o threads threads.c
 *
 * Run on MerlionOS:
 *   run-user threads
 */
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>

static pthread_mutex_t counter_lock = PTHREAD_MUTEX_INITIALIZER;
static int counter = 0;

void* worker(void* arg) {
    int id = *(int*)arg;
    for (int i = 0; i < 5; i++) {
        pthread_mutex_lock(&counter_lock);
        counter++;
        printf("Thread %d: counter = %d\n", id, counter);
        pthread_mutex_unlock(&counter_lock);
        usleep(10000); /* 10ms */
    }
    return NULL;
}

int main() {
    pthread_t t1, t2;
    int id1 = 1, id2 = 2;

    printf("Spawning 2 threads...\n");
    pthread_create(&t1, NULL, worker, &id1);
    pthread_create(&t2, NULL, worker, &id2);

    pthread_join(t1, NULL);
    pthread_join(t2, NULL);

    printf("Final counter = %d (expected 10)\n", counter);
    return 0;
}
