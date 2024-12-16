import "./LogoutButton.css";
import React from "react";

function LogoutButton({ onLogout }) {

    return (
        <button onClick={onLogout} className="logout">Logout</button>
    );

}

export default LogoutButton