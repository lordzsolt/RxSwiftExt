//
//  RetryWithBehaviorTests.swift
//  RxSwiftExtDemo
//
//  Created by Anton Efimenko on 17.07.16.
//  Copyright © 2016 RxSwift Community. All rights reserved.
//

import XCTest
import RxSwift
import RxSwiftExt
import RxTests

private enum RepeatTestErrors : Error {
	case fatalError
}

class RepeatWithBehaviorTests: XCTestCase {
	var sampleValues: TestableObservable<Int>!
    var sampleValuesWithError: TestableObservable<Int>!
	let scheduler = TestScheduler(initialClock: 0)
	
	override func setUp() {
		super.setUp()

		sampleValues = scheduler.createColdObservable([
			next(210, 1),
			next(220, 2),
			completed(300)
			])
     
        sampleValuesWithError = scheduler.createColdObservable([
            next(210, 1),
            error(220, RepeatTestErrors.fatalError),
            ])
	}

    //MARK: correct event values
    let immediateCorrectValues = [
        next(210, 1),
        next(220, 2),
        next(510, 1),
        next(520, 2),
        completed(600)]

    let customDelayCorrectValues = [
        next(210, 1),
        next(220, 2),
        next(520, 1),
        next(530, 2),
        next(850, 1),
        next(860, 2),
        completed(940)]

    let exponentialCorrectValues = [
        next(210, 1),
        next(220, 2),
        next(512, 1),
        next(522, 2),
        next(818, 1),
        next(828, 2),
        completed(908)]

    let erroredCorrectValues : [Recorded<Event<Int>>] = [
        next(210, 1),
        error(220, RepeatTestErrors.fatalError)
    ]

    //MARK: immediate repeats

	func testImmediateRepeatWithoutPredicate() {
		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.Immediate(maxCount: 2), scheduler: self.scheduler)
		}
		XCTAssertEqual(res.events, immediateCorrectValues)
	}
	
    func testImmediateRepeatWithError() {
        let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
            return self.sampleValuesWithError.asObservable().repeatWithBehavior(.Immediate(maxCount: 3), scheduler: self.scheduler)
        }
        
        XCTAssertEqual(res.events, erroredCorrectValues)
    }

	func testImmediateRepeatWithPredicate() {
        var isRepeat = false

		// provide simple predicate that returns false on the second repeat
		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.Immediate(maxCount: 3), scheduler: self.scheduler) {_ in
                isRepeat = !isRepeat
				return isRepeat
			}
		}
		
		XCTAssertEqual(res.events, immediateCorrectValues)
	}

	func testImmediateNotRepeatWithPredicate() {
		let correctValues = [
			next(210, 1),
			next(220, 2),
            completed(300)]
		
		// provide simple predicate that always return false (so, sequence will not repeated)
		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.Immediate(maxCount: 3), scheduler: self.scheduler) { _ in
				return false
			}
		}
		
		XCTAssertEqual(res.events, correctValues)
	}

    func testImmediateNotRepeatWithPredicateWithError() {
        let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
            return self.sampleValuesWithError.asObservable().repeatWithBehavior(.Immediate(maxCount: 3), scheduler: self.scheduler) { _ in
                return false
            }
        }
        XCTAssertEqual(res.events, erroredCorrectValues)
    }

    //MARK: delayed repeats

	func testDelayedRepeatWithoutPredicate() {
		let correctValues = [
			next(210, 1),
			next(220, 2),
			next(511, 1),
			next(521, 2),
			next(812, 1),
			next(822, 2),
			completed(902)]
		
		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.Delayed(maxCount: 3, time: 1.0), scheduler: self.scheduler)
		}
		
		XCTAssertEqual(res.events, correctValues)
	}

	func testDelayedRepeatWithPredicate() {
        let correctValues = [
            next(210, 1),
            next(220, 2),
            next(511, 1),
            next(521, 2),
            next(812, 1),
            next(822, 2),
            completed(902)]

		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.Delayed(maxCount: 3, time: 1.0), scheduler: self.scheduler) { _ in
				return true
			}
		}
		
		XCTAssertEqual(res.events, correctValues)
	}

    func testDelayedNotRepeatWithPredicate() {
		let correctValues = [
			next(210, 1),
			next(220, 2),
			completed(300)]
		
		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.Delayed(maxCount: 3, time: 5.0), scheduler: self.scheduler) { _ in
				return false
			}
		}
		
		XCTAssertEqual(res.events, correctValues)
	}

    func testDelayedNotRepeatWithPredicateWithError() {
        let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
            return self.sampleValuesWithError.asObservable().repeatWithBehavior(.Delayed(maxCount: 3, time: 5.0), scheduler: self.scheduler) { _ in
                return false
            }
        }
        XCTAssertEqual(res.events, erroredCorrectValues)
    }

    //MARK: exponential delay repeats

	func testExponentialRepeatWithoutPredicate() {
		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.ExponentialDelayed(maxCount: 3, initial: 2.0, multiplier: 2.0), scheduler: self.scheduler)
		}
		XCTAssertEqual(res.events, exponentialCorrectValues)
	}

	func testExponentialRepeatWithPredicate() {
		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.ExponentialDelayed(maxCount: 3, initial: 2.0, multiplier: 2.0), scheduler: self.scheduler) { _ in
				return true
			}
		}
		XCTAssertEqual(res.events, exponentialCorrectValues)
	}

	func testExponentialNotRepeatWithPredicate() {
        let correctValues = [
            next(210, 1),
            next(220, 2),
            completed(300)]

		let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.ExponentialDelayed(maxCount: 3, initial: 2.0, multiplier: 2.0), scheduler: self.scheduler) { _ in
				return false
			}
		}
		
		XCTAssertEqual(res.events, correctValues)
	}

    func testExponentialNotRepeatWithPredicateWithError() {
        let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
            return self.sampleValuesWithError.asObservable().repeatWithBehavior(.ExponentialDelayed(maxCount: 3, initial: 2.0, multiplier: 2.0), scheduler: self.scheduler) { _ in
                return false
            }
        }
        XCTAssertEqual(res.events, erroredCorrectValues)
    }

    //MARK: custom delay repeats

    // custom delay calculator
    let customCalculator: (UInt) -> Double = { attempt in
        switch attempt {
        case 1: return 10.0
        case 2: return 30.0
        default: return 0
        }
    }

	func testCustomTimerRepeatWithoutPredicate() {
		let res = scheduler.start(0, subscribed: 0, disposed: 2000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.CustomTimerDelayed(maxCount: 3, delayCalculator: self.customCalculator), scheduler: self.scheduler)
		}
		XCTAssertEqual(res.events, customDelayCorrectValues)
	}

	func testCustomTimerRepeatWithPredicate() {
        let res = scheduler.start(0, subscribed: 0, disposed: 2000) { () -> Observable<Int> in
			return self.sampleValues.asObservable().repeatWithBehavior(.CustomTimerDelayed(maxCount: 3, delayCalculator: self.customCalculator), scheduler: self.scheduler) { _ in
				return true
			}
		}
		XCTAssertEqual(res.events, customDelayCorrectValues)
	}

    func testCustomTimerRepeatWithPredicateWithError() {
        let res = scheduler.start(0, subscribed: 0, disposed: 1000) { () -> Observable<Int> in
            return self.sampleValuesWithError.asObservable().repeatWithBehavior(.CustomTimerDelayed(maxCount: 3, delayCalculator: self.customCalculator), scheduler: self.scheduler) { _ in
                return false
            }
        }
        XCTAssertEqual(res.events, erroredCorrectValues)
    }

}
