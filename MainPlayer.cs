using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class MainPlayer : MonoBehaviour
{
    public static MainPlayer Instance;

    public enum PlayerState { Idle, Walking, Sprinting, Crouching }

    public PlayerState currentState;

    private float idleTimer;

    private Camera cam;

    private CharacterController controller;

    private MeshRenderer capsuleMesh;

    private float defaultHeight;

    private Vector3 camDefaultRelativePos;

    public bool hideCapsule = true;

    public float mouseSensitivityX = 0.1f;

    public float mouseSensitivityY = 0.1f;

    public float walkSpeed = 5f;

    public float baseSprintSpeed = 10f;

    public bool useBase = true;

    public float sprintMultiplier = 1.5f;

    public float jumpMultiplier = 1.5f;

    public float gravity = -20f;

    public float jumpDelay = 0.2f;

    public float crouchHeight = 1f;

    public float crouchSpeed = 2.5f;

    public float crouchTransitionSpeed = 10f;

    public bool holdCrouch = true;

    private bool isCrouchingToggle = false;

    public float stamina = 100f;

    public float maxStamina = 100f;

    public float staminaUsage = 10f;

    public float staminaUsageTime = 100f; // ms

    public float staminaGain = 5f;

    public float staminaGainTime = 100f; // ms

    public bool infiniteStamina = false;

    public bool jumpUsesStamina = true;

    public float jumpStamina = 15f;

    public bool inAir;

    private Vector3 velocity;

    private float verticalRotation = 0f;

    private float nextJumpTime;

    private float nextStaminaLoss;

    private float nextStaminaGain;

    void Awake()
    {
        Instance = this;
        controller = GetComponent<CharacterController>();
        defaultHeight = controller.height;

        if (TryGetComponent<Rigidbody>(out Rigidbody rb)) rb.freezeRotation = true;

        cam = GetComponentInChildren<Camera>();
        camDefaultRelativePos = cam.transform.localPosition;
        capsuleMesh = GetComponent<MeshRenderer>();

        if (hideCapsule && capsuleMesh != null) capsuleMesh.enabled = false;

        Cursor.lockState = CursorLockMode.Locked;
    }

    void LateUpdate()
    {
        var keyboard = Keyboard.current;
        var mouse = Mouse.current;
        if (keyboard == null || mouse == null) return;

        Vector2 moveInput = Vector2.zero;
        if (keyboard.wKey.isPressed) moveInput.y += 1;
        if (keyboard.sKey.isPressed) moveInput.y -= 1;
        if (keyboard.aKey.isPressed) moveInput.x -= 1;
        if (keyboard.dKey.isPressed) moveInput.x += 1;

        if (moveInput.magnitude > 1) moveInput.Normalize();

        Vector2 lookInput = mouse.delta.ReadValue();
        bool sprintHeld = keyboard.leftShiftKey.isPressed;
        bool jumpPressed = keyboard.spaceKey.wasPressedThisFrame;

        if (holdCrouch) isCrouchingToggle = keyboard.leftCtrlKey.isPressed;
        else if (keyboard.leftCtrlKey.wasPressedThisFrame) isCrouchingToggle = !isCrouchingToggle;

        bool isMoving = moveInput.sqrMagnitude > 0.01f;

        if (isMoving || lookInput.sqrMagnitude > 0.01f || jumpPressed) idleTimer = 0;
        else idleTimer += Time.deltaTime;

        if (isCrouchingToggle) currentState = PlayerState.Crouching;
        else if (isMoving && sprintHeld && moveInput.y > 0 && stamina > 0) currentState = PlayerState.Sprinting;
        else if (isMoving) currentState = PlayerState.Walking;
        else currentState = (idleTimer >= 10f) ? PlayerState.Idle : PlayerState.Walking;

        transform.Rotate(Vector3.up * (lookInput.x * mouseSensitivityX));
        verticalRotation -= (lookInput.y * mouseSensitivityY);
        verticalRotation = Mathf.Clamp(verticalRotation, -90f, 90f);
        cam.transform.localRotation = Quaternion.Euler(verticalRotation, 0f, 0f);

        float targetHeight = (currentState == PlayerState.Crouching) ? crouchHeight : defaultHeight;
        float lastHeight = controller.height;

        controller.height = Mathf.Lerp(controller.height, targetHeight, Time.deltaTime * crouchTransitionSpeed);

        Vector3 newCenter = controller.center;
        newCenter.y -= (lastHeight - controller.height) / 2f; // fixed issue where crouching will make inAir true
        controller.center = newCenter;

        float heightDiff = defaultHeight - controller.height;
        cam.transform.localPosition = new Vector3(camDefaultRelativePos.x, camDefaultRelativePos.y - heightDiff, camDefaultRelativePos.z);

        inAir = !controller.isGrounded;
        if (inAir) velocity.y += gravity * Time.deltaTime;
        else if (velocity.y < 0) velocity.y = -2f;

        if (jumpPressed && !inAir && Time.time > nextJumpTime && currentState != PlayerState.Crouching)
        {
            if (!jumpUsesStamina || stamina >= jumpStamina || infiniteStamina)
            {
                velocity.y = Mathf.Sqrt(jumpMultiplier * -2f * gravity);
                nextJumpTime = Time.time + jumpDelay;
                if (jumpUsesStamina && !infiniteStamina) stamina -= jumpStamina;
            }
        }

        float currentSpeed = walkSpeed;
        if (currentState == PlayerState.Sprinting) currentSpeed = useBase ? baseSprintSpeed : walkSpeed * sprintMultiplier;
        else if (currentState == PlayerState.Crouching) currentSpeed = crouchSpeed;

        Vector3 moveDir = transform.right * moveInput.x + transform.forward * moveInput.y;
        controller.Move(moveDir * currentSpeed * Time.deltaTime);
        controller.Move(velocity * Time.deltaTime);

        if (infiniteStamina)
        {
            stamina = maxStamina;
        }
        else
        {
            if (currentState == PlayerState.Sprinting && controller.velocity.magnitude > 0.5f)
            {
                if (Time.time > nextStaminaLoss)
                {
                    stamina -= staminaUsage;
                    nextStaminaLoss = Time.time + (staminaUsageTime / 1000f);
                }
            }
            else if (stamina < maxStamina && Time.time > nextStaminaGain)
            {
                stamina += staminaGain;
                nextStaminaGain = Time.time + (staminaGainTime / 1000f);
            }
            stamina = Mathf.Clamp(stamina, 0, maxStamina);
        }
    }
}
