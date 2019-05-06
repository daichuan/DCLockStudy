### iOS开发中的锁

本人对锁没有深入理解，只是看了几篇文章，在这里做一下简单的总结。

iOS开发中，锁是用来解决线程安全的问题的工具。那么线程安全是什么？

#### 线程安全

------

线程安全：多线程操作共享数据的时候，如果出现了意想不到的结果，就是线程不安全。反之就是线程安全；

或者这么说是不是更容易听懂，多个线程同时对一个数据进行修改的时候，如果不能保证多个线程的执行顺序，就会出现意想不到的结果，这个时候就线程不安全了。

貌似怎么说都不行了，那么就举个例子吧；

```objective-c
- (void)threadNotSafe {
   __block NSInteger total = 0;
    for (NSInteger index = 0; index < 3; index++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            total += 1;
            NSLog(@"total: %ld", total);
            total -= 1;
            NSLog(@"total: %ld", total);
        });
    }
}
/*
第一次打印结果
2019-05-06 11:04:33.937462+0800 DCLockStudy[5270:410073] total: 1
2019-05-06 11:04:33.937462+0800 DCLockStudy[5270:410074] total: 2
2019-05-06 11:04:33.937466+0800 DCLockStudy[5270:410075] total: 3
2019-05-06 11:04:33.937617+0800 DCLockStudy[5270:410075] total: 2
2019-05-06 11:04:33.937617+0800 DCLockStudy[5270:410073] total: 1
2019-05-06 11:04:33.937617+0800 DCLockStudy[5270:410074] total: 2
第二次打印结果
2019-05-06 11:06:50.198993+0800 DCLockStudy[5320:416449] total: 1
2019-05-06 11:06:50.198994+0800 DCLockStudy[5320:416450] total: 2
2019-05-06 11:06:50.199020+0800 DCLockStudy[5320:416452] total: 3
2019-05-06 11:06:50.199187+0800 DCLockStudy[5320:416450] total: 2
2019-05-06 11:06:50.199187+0800 DCLockStudy[5320:416449] total: 1
2019-05-06 11:06:50.199253+0800 DCLockStudy[5320:416452] total: 0
*/
```

上面这段代码，分别执行两次，打印结果不一样。也就是不能确定代码执行顺序和执行结果，是线程不安全的；

再看下面这段代码

```objective-c
- (void)threadSafe {
    __block NSInteger total = 0;
    NSLock *myLock = [[NSLock alloc]init];
    for (NSInteger index = 0; index < 3; index++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [myLock lock];
            total += 1;
            NSLog(@"total: %ld", total);
            total -= 1;
            NSLog(@"total: %ld", total);
            [myLock unlock];
        });
    }
}
/*
第一次打印结果
2019-05-06 11:10:03.678707+0800 DCLockStudy[5351:422830] total: 1
2019-05-06 11:10:03.678872+0800 DCLockStudy[5351:422830] total: 0
2019-05-06 11:10:03.678978+0800 DCLockStudy[5351:422829] total: 1
2019-05-06 11:10:03.679057+0800 DCLockStudy[5351:422829] total: 0
2019-05-06 11:10:03.679189+0800 DCLockStudy[5351:422828] total: 1
2019-05-06 11:10:03.679286+0800 DCLockStudy[5351:422828] total: 0
第二次打印结果
2019-05-06 11:14:52.524955+0800 DCLockStudy[5406:431979] total: 1
2019-05-06 11:14:52.525092+0800 DCLockStudy[5406:431979] total: 0
2019-05-06 11:14:52.525224+0800 DCLockStudy[5406:431980] total: 1
2019-05-06 11:14:52.525303+0800 DCLockStudy[5406:431980] total: 0
2019-05-06 11:14:52.525413+0800 DCLockStudy[5406:431978] total: 1
2019-05-06 11:14:52.525511+0800 DCLockStudy[5406:431978] total: 0
*/
```

两次打印结果一样，为什么呢？因为加了锁，哈哈哈；那么接下来我们来简单说一下锁；

#### 锁的几个的定义

------

- 临界区：每个进程中访问临界资源的那段程序称为临界区，每次只允许一个进程进入临界区，进入后不允许其他进程进入。

- 互斥锁：用于保护临界区，确保同一时间只有一个线程访问数据。对共享资源的访问，先对互斥量进行加锁，如果互斥量已经上锁，调用线程会阻塞，直到互斥量被解锁。在完成了对共享资源的访问后，要对互斥量进行解锁。

接下来主要讲几种锁 [自旋锁OSSpinLock](#自旋锁osspinlock)、[信号量](#信号量)、[pthread_mutex](#pthread_mutex)、[NSLock](#nslock)、[NSCondition](nscondition)、[NSRecursiveLock](#nsrecursivelock)、[NSConditionLock](#nsconditionlock)、[@synchronized](#@synchronized)。这里参考了[深入理解iOS开发中的锁](https://bestswifter.com/ios-lock/#nsconditionlock)；

然后这些锁我在学习过程中写了一个简单的[demo](https://github.com/daichuan/DCLockStudy)，里面有他们的使用方法；

#### 自旋锁OSSpinLock

------

自旋锁与互斥锁类似，它不是通过休眠使进程阻塞，而是在获取锁之前一直处于忙等(自旋)阻塞状态。一般用于锁持有的时间短，而且线程并不希望在重新调度上花太多的成本。

自旋锁与互斥锁的区别：线程在申请自旋锁的时候，线程不会被挂起，而是处于忙等的状态。

我所知道的自旋锁只有OSSpinLock，不过YY大神已经说过OSSpinLock不再安全了，因此这里不做过多的介绍，如果有兴趣可以去看[不再安全的 OSSpinLock](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/);

#### 信号量

------

dispatch_semaphore的实现原理和自旋锁不一样，是根据信号量判断的，首先会将信号量-1，并判断是否大于等于0，如果是，则返回0，并继续执行后续代码，否则，使线程进入睡眠状态，让出cpu时间。直到信号量大于0或者超时，则线程会被重新唤醒执行后续操作。

使用方法如下

```objective-c
- (void)__dispatch_semaphore{
    /**
        dispatch_semaphore_create(1)： 传入值必须 >=0, 若传入为 0 则阻塞线程并等待timeout,时间到后会执行其后的语句
        dispatch_semaphore_wait(signal, overTime)：可以理解为 lock,会使得 signal 值 -1
        dispatch_semaphore_signal(signal)：可以理解为 unlock,会使得 signal 值 +1
    
        停车场剩余4个车位，那么即使同时来了四辆车也能停的下。如果此时来了五辆车，那么就有一辆需要等待。
        信号量的值（signal）就相当于剩余车位的数目，dispatch_semaphore_wait 函数就相当于来了一辆车，dispatch_semaphore_signal 就相当于走了一辆车。停车位的剩余数目在初始化的时候就已经指明了（dispatch_semaphore_create（long value）），调用一次 dispatch_semaphore_signal，剩余的车位就增加一个；调用一次dispatch_semaphore_wait 剩余车位就减少一个；当剩余车位为 0 时，再来车（即调用 dispatch_semaphore_wait）就只能等待。有可能同时有几辆车等待一个停车位。有些车主没有耐心，给自己设定了一段等待时间，这段时间内等不到停车位就走了，如果等到了就开进去停车。而有些车主就像把车停在这，所以就一直等下去。
    */
    dispatch_semaphore_t signal = dispatch_semaphore_create(1);//传入值必须>=0;如果传入0，
    dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW,2.0f * NSEC_PER_SEC);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"线程1等待中。。。");
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"线程1");
        sleep(1);
        dispatch_semaphore_signal(signal);
        NSLog(@"线程1发送信号");
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"线程2等待中。。。");
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"线程2");
        sleep(1);
        dispatch_semaphore_signal(signal);
        NSLog(@"线程2发送信号");
    });
}
```

#### pthread_mutex

------

pthread_mutex 表示互斥锁。互斥锁的实现原理与信号量非常相似，不是使用忙等，而是阻塞线程并睡眠，需要进行上下文切换。

使用方法如下：

```objective-c
- (void)__pthread_mutex_t{
    /**
     声明 pthread_mutex_t pMutex;
        创建一个互斥锁pthread_mutex_init(&pMutex,PTHREAD_MUTEX_NORMAL);
         PTHREAD_MUTEX_NORMAL 缺省类型，也就是普通锁。当一个线程加锁以后，其余请求锁的线程将形成一个等待队列，并在解锁后先进先出原则获得锁。
         PTHREAD_MUTEX_ERRORCHECK 检错锁，如果同一个线程请求同一个锁，则返回 EDEADLK，否则与普通锁类型动作相同。这样就保证当不允许多次加锁时不会出现嵌套情况下的死锁。
         PTHREAD_MUTEX_RECURSIVE 递归锁，允许同一个线程对同一个锁成功获得多次，并通过多次 unlock 解锁。
         PTHREAD_MUTEX_DEFAULT 适应锁，动作最简单的锁类型，仅等待解锁后重新竞争，没有等待队列。
        加锁 pthread_mutex_lock(&pMutex);
        解锁 pthread_mutex_unlock(&pMutex);
 */
    //线程1
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"线程1加锁");
        pthread_mutex_lock(&pMutex);
        sleep(1);
        NSLog(@"线程1");
        pthread_mutex_unlock(&pMutex);
        NSLog(@"线程1解锁");
    });
    //线程2
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1); //保证线程1先加锁
        NSLog(@"线程2加锁");
        pthread_mutex_lock(&pMutex);
        NSLog(@"线程2");
        pthread_mutex_unlock(&pMutex);
        NSLog(@"线程2解锁");
    });
}
```

pthread_mutex 还支持递归锁，只要将类型设置为`PTHREAD_MUTEX_RECURSIVE`就可以。

#### NSLock

------

NSLock是OC以对象的形式暴露给开发者的一种锁，其实NSLock只是在内部封装了一个`pthread_mutex`,属性为`PTHREAD_MUTEX_ERRORCHECK`,它会损失一定性能换来错误提示。

使用方法如下：

```objective-c
NSLock *lock = [NSLock new];
[lock lock];
//需要执行的代码
[lock unlock];
```

NSLock遵守了`NSLocking`协议，`NSLocking`协议其实很简单，只需要满足两个方法

```objective-c
@protocol NSLocking
- (void)lock;
- (void)unlock;
@end
```

在这个基础上，NSLock还自己提供两个方法

```objective-c
- (BOOL)tryLock;
- (BOOL)lockBeforeDate:(NSDate *)limit;
```

-  `tryLock` 尝试获取锁，如果这个时候，别的线程添加了锁，则返回`NO`，不会阻塞线程;

- ` lockBeforeDate`尝试在某个时间之前获取锁，如果在这个时间内没有获取到锁则返回`NO`，不会阻塞线程;

#### NSCondition

------

NSCondition其实是通过封装了一个互斥锁和条件变量，把互斥锁的lock方法和条件变量的wait/signal统一在NSCondition对象中，暴露给使用者。

NSCondition的加锁过程和NSLock几乎一致，耗时上应该差不多。

使用方法如下：

```objective-c
- (void)__NSCondition{
    /** 条件变量
     wait：进入等待状态
     waitUntilDate:：让一个线程等待一定的时间
     signal：唤醒一个等待的线程
     broadcast：唤醒所有等待的线程
     */
    //线程1
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.condition lock];
        NSLog(@"线程1获取到锁，并进入等待状态");
        [self.condition wait];
        NSLog(@"线程1等待完成");
        [self.condition unlock];
        NSLog(@"线程1解锁");
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.condition lock];
        NSLog(@"线程2获取到锁，并进入等待状态");
        [self.condition wait];
        NSLog(@"线程2等待完成");
        [self.condition unlock];
        NSLog(@"线程2解锁");
    });
    
    //线程3
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
        NSLog(@"线程3，唤醒一个等待线程");
        [self.condition signal];
        
        sleep(2);
        NSLog(@"线程3，唤醒所有等待线程");
        [self.condition broadcast];
    });
}

```

#### NSConditionLock

------

`NSConditionLock` 借助 `NSCondition` 来实现，它的本质就是一个生产者-消费者模型。“条件被满足”可以理解为生产者提供了新的内容。`NSConditionLock` 的内部持有一个 `NSCondition` 对象，以及 `_condition_value` 属性，在初始化时就会对这个属性进行赋值。

使用方法如下：

```objective-c
- (void)__NSConditionLock{
    /**条件锁  NSConditionLock
        因为遵守了NSLocking协议，所以可以无条件加锁lock，
     */
    dispatch_queue_t conditionLockQueue = dispatch_queue_create("conditionLockQueue", DISPATCH_QUEUE_CONCURRENT);
    //线程1
    dispatch_async(conditionLockQueue, ^{
        NSLog(@"进入线程1，添加条件锁 = 2，如果condition != 2,则线程阻塞");
        [self.conditionLock lockWhenCondition:2];
        NSLog(@"线程1加锁成功，lockWhenCondition:2");
        [self.conditionLock unlock];
        NSLog(@"线程1解锁锁成功，unlockWithCondition:1");
    });
    
    //线程2
    dispatch_async(conditionLockQueue, ^{
        sleep(1); //保证线程3先执行
        NSLog(@"进入线程2，尝试添加条件锁 = 1");
        if([self.conditionLock tryLockWhenCondition:1]){
            NSLog(@"线程2加锁成功，lockWhenCondition:1");
            [self.conditionLock unlockWithCondition:2];
            NSLog(@"线程2解锁成功，unlockWithCondition:1");
        }else{
            NSLog(@"线程2加锁失败");
        }
    });
    
    //线程3
    dispatch_async(conditionLockQueue, ^{
//        sleep(1); //保证线程2先执行
        NSLog(@"进入线程3，尝试添加条件锁 = 0");
        if([self.conditionLock tryLockWhenCondition:0]){
            NSLog(@"线程3加锁成功，lockWhenCondition:0");
            [self.conditionLock unlockWithCondition:1];
            NSLog(@"线程3解锁成功，unlockWithCondition:1");
        }else{
            NSLog(@"线程3加锁失败");
        }
    });
    
    /** 先进入线程1，条件不满足，线程1阻塞，
        进入线程3，线程3满足条件，线程3加锁，线程3解锁并将条件设置为1；
        进入线程2，线程满足条件，线程2加锁，线程2解锁，并将条件设置为2；
        因为条件为2，线程1满足条件了，线程1不在阻塞，线程1加锁，线程1解锁；
     */
}
```

#### NSRecursiveLock

------

递归锁是通过`pthread_mutex_lock`函数来实现的。

`NSRecursiveLock` 与 `NSLock` 的区别在于内部封装的 `pthread_mutex_t` 对象的类型不同，前者的类型为 `PTHREAD_MUTEX_RECURSIVE`。

使用方法如下：

```objective-c
- (void)__NSRecursiveLock{
    /** NSRecursiveLock递归锁
        它可以被同一线程多次请求，但不会引起死锁。这主要是用在循环或者递归操作场景中。
     */
    /** 如果用普通锁，当第二次进入递归方法时，尝试加锁，但是这个时候该线程还处于锁定，所以线程阻塞，相互等待造成死锁。
     所以这个时候可以用一个递归锁，允许同一线程多次请求，并且不会死锁；
     NSRecursiveLock 递归锁和NSLock一样也有tryLock和lockBeforeDate，用法一样；
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^ recursiveMethod)(NSInteger);
        recursiveMethod = ^(NSInteger num){
            //    [self.myLock lock];
            [self.recursiveLock lock];
            if(num > 0){
                num --;
                NSLog(@"start num = %ld, mutableArray[0] = %@",num,self.mutableArray[0]);
                sleep(1);
                [self.mutableArray replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"replace = %ld",num]];
                NSLog(@"end num = %ld, mutableArray[0] = %@",num,self.mutableArray[0]);
                recursiveMethod(num);
            }
            //    [self.myLock unlock];
            [self.recursiveLock unlock];
        };
        recursiveMethod(5);
    });
}
```

#### @synchronized

------

这其实是一个OC层面的锁，主要通过牺牲新能来换取语法上的简洁与可读。

我们知道 @synchronized 后面需要紧跟一个 OC 对象，它实际上是把这个对象当做锁来使用。这是通过一个哈希表来实现的，OC 在底层使用了一个互斥锁的数组(你可以理解为锁池)，通过对对象去哈希值来得到对应的互斥锁。

具体实现原理可以参考 [关于 @synchronized，这儿比你想知道的还要多](http://yulingtianxia.com/blog/2015/11/01/More-than-you-want-to-know-about-synchronized/)。

#### [demo]

这是我自己学习的时候写的一个[demo](https://github.com/daichuan/DCLockStudy)，是各种锁的使用。上面的代码基本都是这个demo的代码；

#### 参考资料

------

1、[深入理解iOS开发中的锁](https://bestswifter.com/ios-lock/#nsconditionlock)

2、[iOS的线程安全与锁](http://www.cocoachina.com/ios/20171218/21570.html)
