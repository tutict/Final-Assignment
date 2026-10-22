package com.tutict.finalassignmentcloud.auth.exception;

/**
 * 注册用户名已被占用。与“注册失败”区分开，客户端据此提示用户换一个用户名，
 * 而不是把可重试的故障和不可重试的冲突混成同一个 409。
 */
public class UsernameAlreadyExistsException extends RuntimeException {

    private final String username;

    public UsernameAlreadyExistsException(String username) {
        super("Username already exists: " + username);
        this.username = username;
    }

    public String getUsername() {
        return username;
    }
}
