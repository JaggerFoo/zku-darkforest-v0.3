/*
    Prove: I know (x1,y1,x2,y2,x3,y3,p2,r2,distMax, energy) such that:
    - x2^2 + y2^2 <= r^2
    - perlin(x2, y2) = p2
    - (x1-x2)^2 + (y1-y2)^2 <= distMax^2
    - (x2-x3)^2 + (y2-y3)^2 <= distMax^2
    - (x3-x1)^2 + (y3-y1)^2 <= distMax^2
    - MiMCSponge(x1,y1) = pub1
    - MiMCSponge(x2,y2) = pub2
*/

include "mimcsponge.circom";
include "comparators.circom";
include "range_proof.circom";

// include "../perlin/compiled.circom"

template Main() {
    /* Starting Planet Coordinates */
    signal input x1;
    signal input y1;
    /* Second Planet Coordinates */
    signal input x2;
    signal input y2;
    /* Third Planet Coordinates */
    signal input x3;
    signal input y3;
    signal input p2;
    signal input r;
    signal input distMax;
    signal input energy; // New signal, distance to not exceed when jumping

    signal output pub1;
    signal output pub2;
    signal output pub3; // Add a third planet, need to modify 

    
    /* Check that the player energy is not greater than the game max distance */
    signal output energy_valid_flag;
    var eng_exceeds_flag = 0;
    if (energy > distMax) {
        eng_exceeds_flag = 1;
    }
    energy_valid_flag <-- eng_exceeds_flag;
    energy_valid_flag === 0;


    /* Check if the points create a triangle */
    signal triangle;
    var isTriangle = (x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2)) == 0 ? 0 : 1;
    triangle <-- isTriangle;
    triangle === 1;



    /* check abs(x1), abs(y1), abs(x2), abs(y2) < 2 ** 32 */
    component rp = MultiRangeProof(6, 40, 2 ** 32);
    rp.in[0] <== x1;
    rp.in[1] <== y1;
    rp.in[2] <== x2;
    rp.in[3] <== y2;
    rp.in[4] <== x3;
    rp.in[5] <== y3;

    /* make sure the other planets fit the universe */
    /* check x2^2 + y2^2 < r^2                      */
    component comp2 = LessThan(32);
    signal x2Sq;
    signal y2Sq;
    signal r2Sq;
    x2Sq <== x2 * x2;
    y2Sq <== y2 * y2;
    r2Sq <== r * r;
    comp2.in[0] <== x2Sq + y2Sq;
    comp2.in[1] <== r2Sq;
    comp2.out === 1;

    component comp3 = LessThan(32);
    signal x3Sq;
    signal y3Sq;
    signal r3Sq;
    x3Sq <== x3 * x3;
    y3Sq <== y3 * y3;
    r3Sq <== r * r;
    comp3.in[0] <== x3Sq + y3Sq;
    comp3.in[1] <== r3Sq;
    comp3.out === 1;

    /* Check that planets distances do not exceed energy of player     */
    /* planet 1 to planet2, planet 2 to planet 3, planet 3 to planet 1 */

    signal diffX12sq;
    diffX12sq <== (x1 - x2) * (x1 - x2);
    signal diffY12sq;
    diffY12sq <== (y1 - y2) * (y1 - y2);

    signal diffX23sq;
    diffX23sq <== (x2 - x3) * (x2 - x3);
    signal diffY23sq;
    diffY23sq <== (y2 - y3) * (y2 - y3);

    signal diffX31sq;
    diffX31sq <== (x3 - x1) * (x3 - x1);
    signal diffY31sq;
    diffY31sq <== (y3 - y1) * (y3 - y1);

    component ltDist1 = LessThan(32);
    ltDist1.in[0] <== diffX12sq + diffY12sq;
    ltDist1.in[1] <== energy * energy + 1;
    ltDist1.out === 1;

    component ltDist2 = LessThan(32);
    ltDist2.in[0] <== diffX23sq + diffY23sq;
    ltDist2.in[1] <== energy * energy + 1;
    ltDist2.out === 1;

    component ltDist3 = LessThan(32);
    ltDist3.in[0] <== diffX31sq + diffY31sq;
    ltDist3.in[1] <== energy * energy + 1;
    ltDist3.out === 1;

    /* check MiMCSponge(x1,y1) = pub1, MiMCSponge(x2,y2) = pub2 */
    /*
        220 = 2 * ceil(log_5 p), as specified by mimc paper, where
        p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    */
    component mimc1 = MiMCSponge(2, 220, 1);
    component mimc2 = MiMCSponge(2, 220, 1);
    component mimc3 = MiMCSponge(2, 220, 1);

    mimc1.ins[0] <== x1;
    mimc1.ins[1] <== y1;
    mimc1.k <== 0;
    mimc2.ins[0] <== x2;
    mimc2.ins[1] <== y2;
    mimc2.k <== 0;
    mimc3.ins[0] <== x3;
    mimc3.ins[1] <== y3;
    mimc3.k <== 0;

    pub1 <== mimc1.outs[0];
    pub2 <== mimc2.outs[0];
    pub3 <== mimc3.outs[0];

}

component main = Main();
