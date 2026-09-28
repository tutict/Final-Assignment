package finalassignmentbackend.reliability;

public final class ConsumerAttempts {

    public static final int MAX_RETRIES = 3;

    private ConsumerAttempts() {
    }

    public static void run(Runnable action) {
        run(action, delay -> {
            try {
                Thread.sleep(delay);
            } catch (InterruptedException ex) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException("consumer retry interrupted", ex);
            }
        });
    }

    @FunctionalInterface
    public interface CheckedAttempt {
        void run() throws Exception;
    }

    public static void runChecked(CheckedAttempt action) {
        run(() -> {
            try {
                action.run();
            } catch (RuntimeException ex) {
                throw ex;
            } catch (Exception ex) {
                throw new RuntimeException(ex);
            }
        });
    }

    static void run(Runnable action, java.util.function.LongConsumer sleeper) {
        for (int attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            try {
                action.run();
                return;
            } catch (RuntimeException ex) {
                if (!retryable(ex) || attempt == MAX_RETRIES) {
                    throw ex;
                }
                sleeper.accept(backoffMillis(attempt));
            }
        }
    }

    static boolean retryable(Throwable failure) {
        Throwable current = failure;
        while (current != null) {
            if (current instanceof IllegalArgumentException || current instanceof com.fasterxml.jackson.core.JsonProcessingException) {
                return false;
            }
            current = current.getCause();
        }
        return true;
    }

    static long backoffMillis(int attempt) {
        return 50L << attempt;
    }
}
