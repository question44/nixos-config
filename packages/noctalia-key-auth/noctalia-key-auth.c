/* Lock-screen security-key check for the patched Noctalia lock screen.
 *
 * Runs the `noctalia-key` PAM stack (pam_u2f only) for the calling user and
 * reports through its exit status: 0 = authenticated, 3 = no FIDO device
 * present (checked first, so an absent key does not spam PAM logs), 1 = any
 * other failure. PAM text messages go to stdout as "info: ..." / "error: ...".
 * The lock screen kills this process to cancel a pending touch. */
#include <fido.h>
#include <pwd.h>
#include <security/pam_appl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

enum { EXIT_AUTH_OK = 0, EXIT_AUTH_FAIL = 1, EXIT_NO_DEVICE = 3 };

static int fido_device_present(void) {
  size_t found = 0;
  fido_dev_info_t *list = fido_dev_info_new(16);
  if (list == NULL)
    return 1; /* unknown: let PAM decide */
  if (fido_dev_info_manifest(list, 16, &found) != FIDO_OK)
    found = 1;
  fido_dev_info_free(&list, 16);
  return found > 0;
}

static int conversation(int n, const struct pam_message **msg, struct pam_response **resp, void *data) {
  (void)data;
  struct pam_response *r = calloc((size_t)n, sizeof(*r));
  if (r == NULL)
    return PAM_BUF_ERR;
  for (int i = 0; i < n; i++) {
    switch (msg[i]->msg_style) {
    case PAM_TEXT_INFO:
      printf("info: %s\n", msg[i]->msg);
      break;
    case PAM_ERROR_MSG:
      printf("error: %s\n", msg[i]->msg);
      break;
    default:
      /* No password input here: answer any prompt with an empty string. */
      r[i].resp = strdup("");
      if (r[i].resp == NULL) {
        for (int j = 0; j < i; j++)
          free(r[j].resp);
        free(r);
        return PAM_BUF_ERR;
      }
    }
    fflush(stdout);
  }
  *resp = r;
  return PAM_SUCCESS;
}

int main(void) {
  fido_init(0);
  if (!fido_device_present())
    return EXIT_NO_DEVICE;

  const struct passwd *pw = getpwuid(getuid());
  if (pw == NULL)
    return EXIT_AUTH_FAIL;

  const struct pam_conv conv = {conversation, NULL};
  pam_handle_t *pamh = NULL;
  int rc = pam_start("noctalia-key", pw->pw_name, &conv, &pamh);
  if (rc != PAM_SUCCESS)
    return EXIT_AUTH_FAIL;
  rc = pam_authenticate(pamh, PAM_DISALLOW_NULL_AUTHTOK);
  pam_end(pamh, rc);
  return rc == PAM_SUCCESS ? EXIT_AUTH_OK : EXIT_AUTH_FAIL;
}
