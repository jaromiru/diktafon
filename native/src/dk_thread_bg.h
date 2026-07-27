/* Backgrounds the calling thread for the duration of an engine call
 * (design.md §6.5). ggml's threadpool workers get GGML_SCHED_PRIO_LOW via
 * the pool params, but thread 0 of every graph compute is the *caller* —
 * a Dart worker-isolate thread — which would otherwise do its share of the
 * matmuls (and spin at the node barriers) at full weight against the UI
 * thread.
 *
 * Android-only: zygote sets RLIMIT_NICE=40, so nice can be restored on the
 * way out. Desktop glibc processes normally run with RLIMIT_NICE=0 — the
 * raise back to the old value would fail and permanently deprioritize a
 * pooled Dart VM thread; desktops have cores to spare, so they skip this.
 * Apple has no per-thread nice at all (XNU QoS shields the UI instead).
 */
#pragma once

#if defined(__ANDROID__)

#include <sys/resource.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <cerrno>

class DkThreadBackgroundScope {
  public:
    DkThreadBackgroundScope() {
        tid_ = (pid_t) syscall(SYS_gettid);
        errno = 0;
        old_nice_ = getpriority(PRIO_PROCESS, (id_t) tid_);
        if (old_nice_ == -1 && errno != 0) {
            return; // unreadable — leave the thread alone
        }
        if (old_nice_ < 10) {
            armed_ = setpriority(PRIO_PROCESS, (id_t) tid_, 10) == 0;
        }
    }

    ~DkThreadBackgroundScope() {
        if (armed_) {
            setpriority(PRIO_PROCESS, (id_t) tid_, old_nice_);
        }
    }

    DkThreadBackgroundScope(const DkThreadBackgroundScope &) = delete;
    DkThreadBackgroundScope & operator=(const DkThreadBackgroundScope &) = delete;

  private:
    pid_t tid_ = 0;
    int old_nice_ = 0;
    bool armed_ = false;
};

#else

class DkThreadBackgroundScope {};

#endif
