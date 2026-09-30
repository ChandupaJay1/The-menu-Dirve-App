<?php

use App\Models\Driver;
use Illuminate\Support\Facades\Hash;

$email = 'Chandupajayalath20@gmail.com';
$driver = Driver::where('email', $email)->first();

if ($driver) {
    $driver->password = Hash::make('password');
    $driver->save();
    echo "Password changed successfully for $email\n";
} else {
    echo "Driver not found. Creating one...\n";
    $driver = Driver::create([
        'name' => 'Chandupa Jayalath',
        'email' => $email,
        'password' => Hash::make('password'),
        'phone' => '0771234567', // dummy phone
        'vehicle_type' => 'Bike',
        'vehicle_number' => 'B-1234',
        'status' => 'available',
    ]);
    echo "Created driver $email with password 'password'.\n";
}
