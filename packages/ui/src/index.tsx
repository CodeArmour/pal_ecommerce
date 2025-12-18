import type { ButtonHTMLAttributes } from "react";

export function PrimaryButton(props: ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      {...props}
      style={{
        padding: "8px 16px",
        borderRadius: 8,
        border: "none",
        background: "#0f766e",
        color: "white",
        fontWeight: 600,
        cursor: "pointer"
      }}
    />
  );
}
